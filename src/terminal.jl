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
    window_title([io])

Get the current terminal window title.
"""
function window_title end

window_title() = window_title(_default_sixel_io())
window_title(io::IO) = _query_terminal(io, "\033[21t", r"\033\]l(.*)\033\\")

"""
    window_icon_title([io])

Get the current terminal window icon title.
"""
function window_icon_title end

window_icon_title() = window_icon_title(_default_sixel_io())
window_icon_title(io::IO) = _query_terminal(io, "\033[20t", r"\033\]L(.*)\033\\")

"""
    window_size([io])

Determine the current terminal window size in pixels.
"""
function window_size end

window_size() = window_size(_default_sixel_io())
window_size(io::IO) = _query_terminal(io, "\033[14t", r"\033\[4;([0-9]*);([0-9]*)t")

"""
    window_position([io])

Determine the current terminal window position in pixels.
"""
function window_position end

window_position() = window_position(_default_sixel_io())
window_position(io::IO) = _query_terminal(io, "\033[13t", r"\033\[3;([0-9]*);([0-9]*)t")


"""
    cursor_position([io])

Determine the current position as (row x col) of the curser on screen in
characters.
"""
function cursor_position end

cursor_position() = cursor_position(_default_sixel_io())
cursor_position(io::IO) = _query_terminal(io, "\033[6n", r"\033\[([0-9]*);([0-9]*)R")
        # an alternative would be "\033[?6n"

"""
    textarea_size([io])

Determine the current terminal textarea size in characters.
"""
function textarea_size end

textarea_size() = textarea_size(_default_sixel_io())
textarea_size(io::IO) = _query_terminal(io, "\033[18t", r"\033\[8;([0-9]*);([0-9]*)t")

"""
    screen_size([io])

Determine the current terminal screen size in characters.
"""
function screen_size end

screen_size() = screen_size(_default_sixel_io())
screen_size(io::IO) = _query_terminal(io, "\033[19t", r"\033\[9;([0-9]*);([0-9]*)t")

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


end  # submodule Terminal

#=--- end of file ---------------------------------------------------------=#
