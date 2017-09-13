#=--- TerminalGraphics / libsixel.jl --------------------------------------=#

"""
The sub-module `LibSixel` provides some basic wrappers to _libsixel_.
It requires _libsixel_ version 1.0.6 or above for full functionality.
"""
module LibSixel

using ColorTypes
using FixedPointNumbers: N0f8

struct SixelError <: Exception
    msg::String
end

import Base: showerror
showerror(io::IO, err::SixelError) = print(io, err.msg)

const PtrToSixelAllocator = Ptr{Void}

"""
The `SixelEncoder` converts files (given as filenames) or raw image data
into a sixel encoded escape sequence and dumps the data to STDOUT.

Equivalent to the `struct` defined by `libsixel::sixel_encoder_t`.
Apparently these two definitions must always be in sync.
"""
struct SixelEncoder
    ref                   ::Cuint                    # reference counter
    allocator             ::PtrToSixelAllocator
    reqcolors             ::Cint
    color_option          ::Cint
    mapfile               ::Cstring
    builtin_palette       ::Cint
    method_for_diffuse    ::Cint
    method_for_largest    ::Cint
    method_for_rep        ::Cint
    quality_mode          ::Cint
    method_for_resampling ::Cint
    loop_mode             ::Cint
    palette_type          ::Cint
    f8bit                 ::Cint
    finvert               ::Cint
    fuse_macro            ::Cint
    fignore_delay         ::Cint
    complexion            ::Cint
    fstatic               ::Cint
    pixelwidth            ::Cint
    pixelheight           ::Cint
    percentwidth          ::Cint
    percentheight         ::Cint
    clipx                 ::Cint
    clipy                 ::Cint
    clipwidth             ::Cint
    clipheight            ::Cint
    clipfirst             ::Cint
    macro_number          ::Cint
    penetrate_multiplexer ::Cint
    encode_policy         ::Cint
    pipe_mode             ::Cint
    verbose               ::Cint
    has_gri_arg_limit     ::Cint
    bgcolor               ::Cstring
    outfd                 ::Cint
    finsecure             ::Cint
    cancel_flag           ::Ptr{Cint}
    dither_cache          ::Ptr{Void}
end

# offset value of pixelformat
const SIXEL_FORMATTYPE_COLOR     = UInt8(0)
const SIXEL_FORMATTYPE_GRAYSCALE = UInt8(1 << 6)
const SIXEL_FORMATTYPE_PALETTE   = UInt8(1 << 7)

@enum( PixelFormat::Cint
     , Pixel_RGB555   = (SIXEL_FORMATTYPE_COLOR     | 0x01) # 15bpp
     , Pixel_RGB565   = (SIXEL_FORMATTYPE_COLOR     | 0x02) # 16bpp
     , Pixel_RGB888   = (SIXEL_FORMATTYPE_COLOR     | 0x03) # 24bpp
     , Pixel_BGR555   = (SIXEL_FORMATTYPE_COLOR     | 0x04) # 15bpp
     , Pixel_BGR565   = (SIXEL_FORMATTYPE_COLOR     | 0x05) # 16bpp
     , Pixel_BGR888   = (SIXEL_FORMATTYPE_COLOR     | 0x06) # 24bpp
     , Pixel_ARGB8888 = (SIXEL_FORMATTYPE_COLOR     | 0x10) # 32bpp
     , Pixel_RGBA8888 = (SIXEL_FORMATTYPE_COLOR     | 0x11) # 32bpp
     , Pixel_GRAY1    = (SIXEL_FORMATTYPE_GRAYSCALE | 0x00) #  1bpp grayscale
     , Pixel_GRAY2    = (SIXEL_FORMATTYPE_GRAYSCALE | 0x01) #  2bpp grayscale
     , Pixel_GRAY4    = (SIXEL_FORMATTYPE_GRAYSCALE | 0x02) #  4bpp grayscale
     , Pixel_GRAY8    = (SIXEL_FORMATTYPE_GRAYSCALE | 0x03) #  8bpp grayscale
     , Pixel_AG88     = (SIXEL_FORMATTYPE_GRAYSCALE | 0x13) # 16bpp gray+alpha
     , Pixel_GA88     = (SIXEL_FORMATTYPE_GRAYSCALE | 0x23) # 16bpp gray+alpha
     , Pixel_PAL1     = (SIXEL_FORMATTYPE_PALETTE   | 0x00) #  1bpp palette
     , Pixel_PAL2     = (SIXEL_FORMATTYPE_PALETTE   | 0x01) #  2bpp palette
     , Pixel_PAL4     = (SIXEL_FORMATTYPE_PALETTE   | 0x02) #  4bpp palette
     , Pixel_PAL8     = (SIXEL_FORMATTYPE_PALETTE   | 0x03) #  8bpp palette
)

# Mapping of Colorant to PixelFormat, only lists the supported ones
const supported_colormaps = Dict(
      ColorTypes.RGB{N0f8}   => Pixel_RGB888,
      ColorTypes.ARGB{N0f8}  => Pixel_ARGB8888,
      ColorTypes.RGBA{N0f8}  => Pixel_RGBA8888,
      ColorTypes.BGR{N0f8}   => Pixel_BGR888,
      ColorTypes.Gray{N0f8}  => Pixel_GRAY8,
      ColorTypes.AGray{N0f8} => Pixel_AG88,
      ColorTypes.GrayA{N0f8} => Pixel_GA88,
)

#= currently not required...
@enum( Colorspace::Cint
     , Colorspace_AUTO     = 0   # choose palette type automatically
     , Colorspace_HLS      = 1   # HLS colorspace (hue, lightness, saturation)
     , Colorspace_RGB      = 2   # RGB colorspace
)

@enum( DitherPaletteType::Cint
     , Palette_MONO_DARK   = 0x0  # monochrome terminal with dark background
     , Palette_MONO_LIGHT  = 0x1  # monochrome terminal with dark background
     , Palette_XTERM16     = 0x2  # xterm 16color
     , Palette_XTERM256    = 0x3  # xterm 256color
     , Palette_VT340_MONO  = 0x4  # vt340 monochrome
     , Palette_VT340_COLOR = 0x5  # vt340 color
     , Palette_G1          = 0x6  # 1bit grayscale
     , Palette_G2          = 0x7  # 2bit grayscale
     , Palette_G4          = 0x8  # 4bit grayscale
     , Palette_G8          = 0x9  # 8bit grayscale
)
=#

const encoder_options = Dict{Symbol,Cint}(
    :INPUT            => 'i',   # -i, --input: specify input file name.
    :OUTPUT           => 'o',   # -o, --output: specify output file name.
    :OUTFILE          => 'o',   # -o, --outfile: specify output file name.
    :SEVENBIT_MODE    => '7',   # -7, --7bit-mode: for 7bit terminals or printers (default)
    :EIGHTBIT_MODE    => '8',   # -8, --8bit-mode: for 8bit terminals or printers
    :COLORS           => 'p',   # -p COLORS, --colors=COLORS: specify number of colors
    :MAPFILE          => 'm',   # -m FILE, --mapfile=FILE: specify set of colors
    :MONOCHROME       => 'e',   # -e, --monochrome: output monochrome sixel image
    :INSECURE         => 'k',   # -k, --insecure: allow to connect to SSL sites without certs
    :INVERT           => 'i',   # -i, --invert: assume the terminal background color
    :HIGH_COLOR       => 'I',   # -I, --high-color: output 15bpp sixel image
    :USE_MACRO        => 'u',   # -u, --use-macro: use DECDMAC and DEVINVM sequences
    :MACRO_NUMBER     => 'n',   # -n MACRONO, --macro-number=MACRONO: specify macro register number
    :COMPLEXION_SCORE => 'C',   # -C COMPLEXIONSCORE, --complexion-score=COMPLEXIONSCORE: specify an number argument for the score of complexion correction.
    :IGNORE_DELAY     => 'g',   # -g, --ignore-delay: render GIF animation without delay
    :STATIC           => 'S',   # -S, --static: render animated GIF as a static image
    :DIFFUSION        => 'd',   # -d DIFFUSIONTYPE, --diffusion=DIFFUSIONTYPE: choose diffusion method which used with -p option.
                                #          DIFFUSIONTYPE is one of them:
                                #            auto     -> choose diffusion type automatically (default)
                                #            none     -> do not diffuse
                                #            fs       -> Floyd-Steinberg method
                                #            atkinson -> Bill Atkinson's method
                                #            jajuni   -> Jarvis, Judice & Ninke
                                #            stucki   -> Stucki's method
                                #            burkes   -> Burkes' method
    :FIND_LARGEST     => 'f',   # -f FINDTYPE, --find-largest=FINDTYPE: choose method for finding the largest dimension of median cut boxes for splitting, make sense only when -p option (color reduction) is specified
                                #         FINDTYPE is one of them:
                                #           auto -> choose finding method automatically (default)
                                #           norm -> simply comparing the range in RGB space
                                #           lum  -> transforming into luminosities before the comparison
    :SELECT_COLOR     => 's',   # -s SELECTTYPE, --select-color=SELECTTYPE: choose the method for selecting representative color from each median-cut box, make sense only when -p option (color reduction) is specified
                                #        SELECTTYPE is one of them:
                                #          auto      -> choose selecting method automatically (default)
                                #          center    -> choose the center of the box
                                #          average    -> calculate the color average into the box
                                #          histogram -> similar with average but considers color histogram
    :CROP             => 'c',   # -c REGION, --crop=REGION: crop source image to fit the specified geometry. REGION should be formatted as '%dx%d+%d+%d'
    :WIDTH            => 'w',   # -w WIDTH, --width=WIDTH: resize image to specified width WIDTH is represented by the following syntax
                                #          auto       -> preserving aspect ratio (default)
                                #          <number>%  -> scale width with given percentage
                                #          <number>   -> scale width with pixel counts
                                #          <number>px -> scale width with pixel counts
    :HEIGHT           => 'h',   # -h HEIGHT, --height=HEIGHT: resize image to specified height HEIGHT is represented by the following syntax
                                #           auto       -> preserving aspect ratio (default)
                                #           <number>%  -> scale height with given percentage
                                #           <number>   -> scale height with pixel counts
                                #           <number>px -> scale height with pixel counts
    :RESAMPLING       => 'r',   # -r RESAMPLINGTYPE, --resampling=RESAMPLINGTYPE: choose resampling filter used with -w or -h option (scaling) RESAMPLINGTYPE is one of them:
                                #          nearest  -> Nearest-Neighbor method
                                #          gaussian -> Gaussian filter
                                #          hanning  -> Hanning filter
                                #          hamming  -> Hamming filter
                                #          bilinear -> Bilinear filter (default)
                                #          welsh    -> Welsh filter
                                #          bicubic  -> Bicubic filter
                                #          lanczos2 -> Lanczos-2 filter
                                #          lanczos3 -> Lanczos-3 filter
                                #          lanczos4 -> Lanczos-4 filter
    :QUALITY          => 'q',   # -q QUALITYMODE, --quality=QUALITYMODE: select quality of color quanlization.
                                #          auto -> decide quality mode automatically (default)
                                #          low  -> low quality and high speed mode
                                #          high -> high quality and low speed mode
                                #          full -> full quality and careful speed mode
    :LOOPMODE         => 'l',   # -l LOOPMODE, --loop-control=LOOPMODE: select loop control mode for GIF animation.
                                #          auto    -> honor the setting of GIF header (default)
                                #          force   -> always enable loop
                                #          disable -> always disable loop
    :PALETTE_TYPE     => 't',   # -t PALETTETYPE, --palette-type=PALETTETYPE: select palette color space type
                                #          auto -> choose palette type automatically (default)
                                #          hls  -> use HLS color space
                                #          rgb  -> use RGB color space
    :BUILTIN_PALETTE  => 'b',   # -b BUILTINPALETTE, --builtin-palette=BUILTINPALETTE: select built-in palette type
                                #          xterm16    -> X default 16 color map
                                #          xterm256   -> X default 256 color map
                                #          vt340mono  -> VT340 monochrome map
                                #          vt340color -> VT340 color map
                                #          gray1      -> 1bit grayscale map
                                #          gray2      -> 2bit grayscale map
                                #          gray4      -> 4bit grayscale map
                                #          gray8      -> 8bit grayscale map
    :ENCODE_POLICY    => 'E',   # -E ENCODEPOLICY, --encode-policy=ENCODEPOLICY: select encoding policy
                                #          auto -> choose encoding policy automatically (default)
                                #          fast -> encode as fast as possible
                                #          size -> encode to as small sixel sequence as possible
    :BGCOLOR          => 'B',   # -B BGCOLOR, --bgcolor=BGCOLOR: specify background color, BGCOLOR is represented by the following syntax
                                #          #rgb
                                #          #rrggbb
                                #          #rrrgggbbb
                                #          #rrrrggggbbbb
                                #          rgb:r/g/b
                                #          rgb:rr/gg/bb
                                #          rgb:rrr/ggg/bbb
                                #          rgb:rrrr/gggg/bbbb
    :PENETRATE        => 'P',   # -P, --penetrate: penetrate GNU Screen using DCS pass-through sequence
    :PIPE_MODE        => 'D',   # -D, --pipe-mode: read source images from stdin continuously
    :VERBOSE          => 'v',   # -v, --verbose: show debugging info
    :VERSION          => 'V',   # -V, --version: show version and license info
    :HELP             => 'H',   # -H, --help: show this help
)

#
#
#  Default encoder instance
#
#

#=-------------------------------------------------------------------------=#
#
#   Binary dependencies & initalisation
#
#=-------------------------------------------------------------------------=#

const depsfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error( "'TerminalGraphics' is not properly installed.\n" *
           "Please run Pkg.build(\"TerminalGraphics\"), then restart Julia." )
end

# use this everywhere accessing libsixel the encoder instance is required
const PtrToSixelEncoder = Ptr{SixelEncoder}

"Handle (pointer) to the default 'libsixel' encoder instance."
const encoder = Ref{PtrToSixelEncoder}(C_NULL)

__init__() = (global encoder[] = encoder_new())


#=-------------------------------------------------------------------------=#
#
#   Function wrappers
#
#=-------------------------------------------------------------------------=#


function encoder_new() ::PtrToSixelEncoder
    enc = Ref{PtrToSixelEncoder}()
    ccall( (:sixel_encoder_new, libsixel), Cint
         , (Ref{PtrToSixelEncoder}, PtrToSixelAllocator)
         , enc, C_NULL
         ) |> throw_on_sixelerror
    return enc[]
end

encoder_unref(enc::PtrToSixelEncoder) ::Void =
    ccall( (:sixel_encoder_unref, libsixel), Void, (PtrToSixelEncoder,), enc )

encoder_setopt(opt::Symbol, val=nothing) = encoder_setopt(encoder[], opt, val)
function encoder_setopt(enc::PtrToSixelEncoder, opt::Symbol, val)
    opt_num = encoder_options[opt]
    v = val === nothing ? C_NULL : string(val)
    ccall( (:sixel_encoder_setopt, libsixel), Cint
         , (PtrToSixelEncoder, Cint, Cstring)
         , enc, opt_num, v) |> throw_on_sixelerror
end

encoder_encode(filename::AbstractString) = encoder_encode(encoder[], filename)
encoder_encode(enc::PtrToSixelEncoder, filename::AbstractString) ::Void =
    ccall( (:sixel_encoder_encode, libsixel), Cint, (PtrToSixelEncoder, Cstring)
         , enc, string(filename)) |> throw_on_sixelerror

encoder_encode_bytes(img::Matrix) = encoder_encode_bytes(encoder[], img)
function encoder_encode_bytes(enc::PtrToSixelEncoder, img::Matrix{C}) where {C<:Colorant}
    eltype(C) !== N0f8 && throw(ArgumentError(
            "'libsixel' can only display 8bit per color channel. " *
            "Convert your image!"))
    pixelformat = supported_colormaps[C]
    width, height = size(img)
    ccall( (:sixel_encoder_encode_bytes, libsixel), Cint
         , (PtrToSixelEncoder, Ptr{Void}, Cint, Cint, Cint, Ptr{Void}, Cint)
         ,  enc, img, width, height, pixelformat, C_NULL, 0
         ) |> throw_on_sixelerror
end

function throw_on_sixelerror(x::Cint) ::Void
    x == 0 && return
    s = ccall( (:sixel_helper_format_error, libsixel), Cstring, (Cint,), x)
    throw(SixelError(Base.unsafe_string(s)))
end


end # module TerminalGraphics.LibSixel


#=--- end of file ---------------------------------------------------------=#
