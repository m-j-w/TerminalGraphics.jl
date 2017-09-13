#=--- TerminalGraphics / integrations / Cairo.jl --------------------------=#

#=-------------------------------------------------------------------------=#
#
#   Integrations for 'Cairo.jl'
#
#   When Cairo is loaded, automatically allow displaying a CairoSurface on
#   the console by drawing to a temporary png file.
#
#=-------------------------------------------------------------------------=#

import Base: display
display(d::TerminalGraphics.SixelDisplay, surface::Cairo.CairoSurface) = begin
    # define a temporary filename and plot to it
    fn = tempname() * ".png"
    isfile(fn) &&
        error("The intended temporary file '$fn' already exists. Try again.")
    Cairo.write_to_png(surface, fn)
    # draw the 'png'
    plottype = string(typeof(plt))
    title = string(typeof(surface))
    size = "size ($(surface.width), $(surface.height))"
    println(d.io, "Drawing $title of $size, temporarily at $fn")
    TerminalGraphics.draw(d.io, fn)
    # delete the 'png'
    isfile(fn) && Base.Filesystem.rm(fn)
    isfile(fn) &&
        warn("The temporary file '$fn' couldn't be deleted. Please inspect.")
end


#=--- end of file ---------------------------------------------------------=#
