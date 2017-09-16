#=--- TerminalGraphics / terminal.jl --------------------------------------=#

"""
Module `Terminal`, a submodule to `TerminalGraphics` provides functions
to query and manipulate features of the terminal emulator displaying the
current Julia session, in particular the Julia REPL.
"""
module Terminal

using .._default_sixel_io

"Helper function to send similar requests to a terminal emulator."
function _commandeer_terminal(io::Base.Terminals.TTYTerminal,
                             command::AbstractString)
    Base.Terminals.raw!(io, true)
    write(io, string(command))
    Base.Terminals.raw!(io, false)
end

"""
Helper function to send similar requests to a terminal emulator,
and expect an answer which is analyzed using a regular expression.
"""
function _query_terminal(io::Base.Terminals.TTYTerminal,
                        question::AbstractString, answer::Regex)
    Base.Terminals.raw!(io, true)
    write(io, string(question))
    response = transcode(String, readavailable(io))
    Base.Terminals.raw!(io, false)
    m = match(answer, response)
    (map(parse, m.captures)...)
end


"""
    windowtitle([io])

Get the title of the current terminal window.
"""
function windowtitle end

windowtitle() = windowtitle(_default_sixel_io())
windowtitle(io::IO) = _query_terminal(io, "\033[21t", r"\033\]l(.*)\033\\")

"""
    window_icon_title([io])

Get the current terminal window icon title.
"""
function window_icon_title end

window_icon_title() = window_icon_title(_default_sixel_io())
window_icon_title(io::IO) = _query_terminal(io, "\033[20t", r"\033\]L(.*)\033\\")

"""
    windowsize([io])

Determine the size of the terminal window in pixels, (width, height).
"""
function windowsize end

windowsize() = windowsize(_default_sixel_io())
windowsize(io::IO) = _query_terminal(io, "\033[14t", r"\033\[4;([0-9]*);([0-9]*)t")

"""
    window_position([io])

Determine the current terminal window position in pixels.
"""
function window_position end

window_position() = window_position(_default_sixel_io())
window_position(io::IO) = _query_terminal(io, "\033[13t", r"\033\[3;([0-9]*);([0-9]*)t")


"""
    cursorposition([io])

Determine the current position of the curser within the textarea in
characters, (row, col).
"""
function cursorposition end

cursorposition() = cursorposition(_default_sixel_io())
cursorposition(io::IO) = _query_terminal(io, "\033[6n", r"\033\[([0-9]*);([0-9]*)R")
        # an alternative would be "\033[?6n"

"""
    textarea([io])

Determine the current terminal textarea size in characters, (cols, rows).
"""
function textarea end

textarea() = textarea(_default_sixel_io())
textarea(io::IO) = _query_terminal(io, "\033[18t", r"\033\[8;([0-9]*);([0-9]*)t")

"""
    screensize([io])

Determine the screen size the terminal window is displayed on, in characters,
(maxcols, maxrows).
"""
function screensize end

screensize() = screensize(_default_sixel_io())
screensize(io::IO) = _query_terminal(io, "\033[19t", r"\033\[9;([0-9]*);([0-9]*)t")

"""
    colors_reverse([io])

Set the terminal to reversed color mode, typically black-on-white.
"""
function colors_reverse end

colors_reverse() = colors_reverse(_default_sixel_io())
colors_reverse(io::IO) = _commandeer_terminal(io, "\033[?5h")

"""
    colors_normal([io])

Set the terminal to normal color mode, typically white-on-black.
"""
function colors_normal end

colors_normal() = colors_normal(_default_sixel_io())
colors_normal(io::IO) = _commandeer_terminal(io, "\033[?5l")


"""
    hassixel([io])

Determine if the terminal emulator supports Sixel graphics.
"""
function hassixel end

hassixel() = hassixel(_default_sixel_io())

hassixel(repl::Base.REPL.AbstractREPL) = hassixel(outstream(repl))

# CSI Ps c  Send Device Attributes (Primary DA).
#     Ps = 0  or omitted -> request attributes from terminal.
#   The response depends on the decTerminalID resource setting.
#     -> CSI ? 1 ; 2 c  ("VT100 with Advanced Video Option")
#     -> CSI ? 1 ; 0 c  ("VT101 with No Options")
#     -> CSI ? 6 c  ("VT102")
#     -> CSI ? 6 2 ; Psc  ("VT220")
#     -> CSI ? 6 3 ; Psc  ("VT320")
#     -> CSI ? 6 4 ; Psc  ("VT420")
#   The VT100-style response parameters do not mean anything by
#   themselves.  VT220 (and higher) parameters do, telling the
#   host what features the terminal supports:
#     Ps = 1  -> 132-columns.
#     Ps = 2  -> Printer.
#     Ps = 3  -> ReGIS graphics.
#     Ps = 4  -> Sixel graphics.
#     Ps = 6  -> Selective erase.
#     Ps = 8  -> User-defined keys.
#     Ps = 9  -> National Replacement Character sets.
#     Ps = 1 5  -> Technical characters.
#     Ps = 1 8  -> User windows.
#     Ps = 2 1  -> Horizontal scrolling.
#     Ps = 2 2  -> ANSI color, e.g., VT525.
#     Ps = 2 9  -> ANSI text locator (i.e., DEC Locator mode).

# Note: it appears e.g. mlterm does not strictly comply.

function hassixel(io::IO)
    Base.Terminals.raw!(io, true)
    write(io, "\033[0c")
    r = transcode(String, Base.readavailable(io))
    Base.Terminals.raw!(io, false)

    # first entry is terminal generation; must be larger than 6 (VT102)
    # Note: it seems MLterm doesn't comply, but a '4' is nowhere else to be
    # found anyway, so just skip this.
    #first(m) <= 6 && return false

    m = map(parse, matchall(r"[0-9]+", r))
    return 4 in m
end

end  # submodule Terminal

#=--- end of file ---------------------------------------------------------=#
