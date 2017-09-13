#=--- TerminalGraphics / integrations / Luxor.jl --------------------------=#

#=-------------------------------------------------------------------------=#
#
#   Integrations for 'Luxor.jl'
#
#   When Luxor is loaded, automatically allow showing a drawing on the
#   console by drawing the underlying file.
#
#=-------------------------------------------------------------------------=#

import Base: display
display(d::TerminalGraphics.SixelDisplay, drw::Luxor.Drawing) = begin
    fn = drw.filename
    isfile(fn) &&
        error("The Luxor drawing holds a filename '$fn' that doesn't exist.")
    drw.surfacetype == "png" ||
        error("Currently, only 'png' Luxor Drawings can be displayed. Sorry.")
    # draw the 'png'
    title = string(typeof(drw))
    size = "size ($(drw.width), $(drw.height))"
    println(d.io, "Drawing $title of $size, at $fn")
    TerminalGraphics.draw(d.io, fn)
end


#=--- end of file ---------------------------------------------------------=#
