#=--- TerminalGraphics / TerminalGraphics.jl ------------------------------=#

#__precompile__(false)

"""
The module `TerminalGraphics` provides capability to display graphical
content in a terminal emulator capable of DEC's Sixel protocol.

Graphical content is rendered using _libsixel_, a library that performs the
conversion into the terminal escape sequence holding the graphics data.

After importing `TerminalGraphics`, _libsixel_ is loaded and integrated into
Julia's multimedia structure.  Matrix-like data is printed by simply using a
`display(MIME"image/sixel", image)` statement.
"""
module TerminalGraphics

using Colors: Colorant, Gray, N0f8, base_colorant_type

"Default to an initialised REPL, or STDOUT otherwise."
_default_sixel_io() =
    isdefined(Base, :active_repl) ? Base.active_repl.t : STDOUT

include("libsixel.jl")      # low-level wrappers of libsixel
include("terminal.jl")      # escape sequences to query the terminal

using .Terminal: hassixel


#=-------------------------------------------------------------------------=#
#
#   Colorspace conversions
#
#=-------------------------------------------------------------------------=#

"""
    convert_image_colordepth(img)

Convert an image, represented by an abstract matrix of element type Colorant,
to a color channel depth of 8 bit, while preserving the original kind of color
space, e.g. `RGB{N0f16}` becomes `RGB{N0f8}`, or `GrayA{N0f32}` becomes
`GrayA{N0f8}`, respectively.  In case the image already has an `N0f8` color
channel depth, this function is a noop.
"""
function convert_image_colordepth(img::AbstractMatrix{C}) where {C<:Colorant}
    colortype = base_colorant_type(C){N0f8}
    convert(Matrix{colortype}, img)
end


#=-------------------------------------------------------------------------=#
#
#   Sixel drawing
#
#=-------------------------------------------------------------------------=#

export draw

"""
    draw([io,] data [; kwargs...])

Draw some data as terminal graphics in a Sixel-enabled terminal
emulator, optionally specified by 'io'.  Use `isdrawable([io,] data)`
to test whether their is support for the type of data to be printed
graphically on a text terminal.  Conversion may be customized using
keyword arguments.

TODO: Implement and explain available keyword arguments.
"""
function draw end

draw(x; kwargs...) = draw(_default_sixel_io(), x; kwargs...)

draw(io::IO, x; kwargs...) = error("""
    Sorry, it appears there is no method yet to draw data of type $(typeof(x)).
    """)

"""
    draw([io,] image_filename)

Draw the image stored in the file `filename` an a Sixel-enabled terminal
emulator.  Uses the image loader of 'libsixel', which supports typically
at least 'png', 'jpeg', 'gif', 'bmp', including animated versions.
"""
# TODO: Redirect the io.
draw(io::IO, filename::AbstractString) = LibSixel.encoder_encode(string(filename))

# TODO: Add this weird type...
# a) AxisArrays.AxisArray{
#        ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}},
#        3,
#        Array{ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}},3},
#        Tuple{ AxisArrays.Axis{:P,StepRange{Int64,Int64}},
#               AxisArrays.Axis{:R,StepRange{Int64,Int64}},
#               AxisArrays.Axis{:S,StepRange{Int64,Int64}}
#             }
#        }

"""
    draw([io,] image::Matrix{C})  where {C<:Colorant}

Draw the image loaded in memory as a matrix of colors 'C' in a Sixel-enabled
terminal emulator.  Uses the sixel encoder of 'libsixel', which performs
dithering and palette computations automatically.

The image is transposed automatically, or depending on the additional keyword
argument `flip::Bool`.
"""
function draw(io::IO, img::Matrix{C}; flip::Bool=true) where {C<:Colorant}
    # TODO: Redirect the io.
    println(io, "Drawing image of size ", size(img), ", ", C, ":")
    image = flip ? Base.permutedims(img, (2,1)) : img
    convimage = convert_image_colordepth(image)
    LibSixel.encoder_encode_bytes(convimage)
end


"""
    draw([io,] image::AbstractArray{C,3})  where {C<:Colorant}

Draw the image loaded in memory as a matrix of colors 'C' in a Sixel-enabled
terminal emulator.  Uses the sixel encoder of 'libsixel', which performs
dithering and palette computations automatically.

TODO: Third dimension appears to be a palette type ?!?
      Array{ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}},3}

The image is transposed automatically, or depending on the additional keyword
argument `flip::Bool`.
"""
function draw(io::IO, img::Array{C,3}; flip::Bool=true) where {C<:Colorant}
    println(io, "Drawing first of a series of images of size ", size(img), ":")
    img = img[:,:,1]
    image = flip ? Base.permutedims(img, (2,1)) : img
    convimage = convert_image_colordepth(image)
    LibSixel.encoder_encode_bytes(image)
end


#=-------------------------------------------------------------------------=#
#
#   Multimedia integration: display(...)
#
#=-------------------------------------------------------------------------=#

"""
    SixelDisplay(io::IO)

Create a `SixelDisplay` to show images on a DEC Sixel enabled terminal using
Julia's multimedia `display` architecture.  Currently, output is always sent
to STDOUT, more specifically to the underlying systems STDOUT.

NOTE: This type must be a `mutable struct` to allow the definition of a
      finalizer.
"""
struct SixelDisplay <: Display
    io
end

# pretend to be able to show all images; if this is inaccurate, an actual
# MethodError will occur later on in the real 'display' function
import Base: displayable
displayable(::SixelDisplay, m::MIME) = startswith(string(m), "image/")


# Forward any displaying request of any object type,
# as long as the target mime type is an 'image/*'
import Base: display
display(d::SixelDisplay, m::MIME, x) = begin
    displayable(d, m) && return draw(d.io, x)
    throw(MethodError(display, (d, m, x)))
end

# Allow to display any image that is represenated as matrix-like
# data of a colorant that can be converted properly to an N0f8
display(d::SixelDisplay, img::AbstractMatrix{C}) where {C<:Colorant} = draw(d.io, img)


#=-------------------------------------------------------------------------=#
#
#   Module initialisation
#
#=-------------------------------------------------------------------------=#

"""
Called by Julia module loaded on successful loading of a new module `m`.
Used to add features to known modules with graphical output,
such as 'Plots.jl'.
"""
_module_loaded_callback(m::Symbol) = begin
    if m in [:Plots, :Cairo, :Luxor]
        isdefined(m) && isa(getfield(Main, m), Module) && begin
            md = string(m) * ".jl"
            include(joinpath(dirname(@__FILE__), "integrations", "$md"))
            info("TerminalGraphics detected $md; integration enabled.")
        end
    end
end

"""
Called when the REPL is initialised, this happens after
the module's `__init__()`, but only if this module is loaded
during an initial Julia startup.
"""
# TODO: add proper type assertions
__repl_init__(repl) = begin
    
    if !hassixel()
        # TODO: Get proper identification of the terminal emulator
        warn("This terminal emulator appears to not support sixel graphics.\n" *
             (" "^9) * "'TerminalGraphics' is not enabled. " *
             "Use w.g. MLTerm or MinTTY.")
        return
    end

    pushdisplay(SixelDisplay(repl.t))

    # Register callbacks to get informed on newly loaded modules
    push!(Base.package_callbacks, _module_loaded_callback)

    # Check for known module integrations.
    for m in [:Plots, :Cairo, :Luxor]
        _module_loaded_callback(m)
    end

    # Give a hint to the user.
    info("TerminalGraphics is now loaded, console graphics enabled.")
end

__init__() = begin

    # The REPL terminal is only available after replinit,
    # so defer integration until that point.

    # if the REPL is already initialised, inject
    # the third party module support manually, otherwise
    # register the callback for when the REPL is ready
    if isdefined(Base, :active_repl)
        __repl_init__(Base.active_repl)
    else
        Base.atreplinit(__repl_init__)
    end

end


end # module TerminalGraphics


#=--- end of file ---------------------------------------------------------=#
