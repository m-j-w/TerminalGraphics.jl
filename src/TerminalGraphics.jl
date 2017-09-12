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

using .Terminal

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
    #LibSixel.encoder_setopt(:PALETTE_TYPE, "hls")
    #LibSixel.encoder_setopt(:ENCODE_POLICY, "fast")
    #LibSixel.encoder_setopt(:STATIC)
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
function draw(io::IO, img::AbstractArray{C,3}; flip::Bool=true) where {C<:Colorant}
    # TODO: Redirect the io.
    warn("IS THIS OUTPUT CORRECT?")
    println(io, "Drawing image of size ", size(img), ":")
    image = flip ? Base.permutedims(img, (2,1)) : img
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
Try to secretly test the terminal emulator for Sixel support by sending
a Sixel escape sequence and observing cursor movement.  If the cursor
moves by an expected number of characters, then we have Sixel support.
Otherwise, sadly no.  Unsupported emulators may either simply eat the
whole escape sequence, e.g. xterm, or print the raw sequence.
"""
_check_sixel_support(io::IO) = begin
    # test with a 6 x 3 * character width image.
    char_height, char_width = Terminal.textarea_size(io)
    test_sixel = rand(Gray{N0f8}, (6, 3*char_width))
    # record the current cursor position
    oldpos = Terminal.cursor_position(io)
    draw(io, test_sixel)
    newpos = Terminal.cursor_position(io)
    return (newpos .- oldpos)
    # TODO: Well, the screen scrolls and the cursor is again in the same
    #       position... How to prevent that?!?
end

"""
Called by Julia module loaded on successful loading of a new module `m`.
Used to add features to known modules with graphical output,
such as 'Plots.jl'.
"""
_module_loaded_callback(m::Symbol) = nothing

"""
Called when the REPL is initialised, this happens after
the module's `__init__()`, but only if this module is loaded
during an initial Julia startup.
"""
_repl_init_callback(repl) = begin
    # TODO: add proper type assertions
    # Create and push our new display / output handler
    pushdisplay(SixelDisplay(repl.t))
end

__init__() = begin

    # Register callbacks to get informed on newly loaded modules
    push!(Base.package_callbacks, _module_loaded_callback)

    # if the REPL is already initialised, inject
    # the third party module support manually, otherwise
    # register the callback for when the REPL is ready
    if isdefined(Base, :active_repl)
        _repl_init_callback(Base.active_repl)
    else
        Base.atreplinit(_repl_init_callback)
    end

    # Give a hint to the user.
    info("Module TerminalGraphics is now loaded. Observe...")

end


end # module TerminalGraphics


#=--- end of file ---------------------------------------------------------=#
