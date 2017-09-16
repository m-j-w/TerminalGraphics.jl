#=--- TerminalGraphics / integrations / Plots.jl --------------------------=#

#=-------------------------------------------------------------------------=#
#
#   Integrations for 'Plots.jl'
#
#   When Plots is loaded, automatically surpass the Plots display
#   function and plot through a temporary png file to display the
#   plot on the terminal.
#
#=-------------------------------------------------------------------------=#

# Note on GR backend of Plots. From jheinen: Internally, GR dumps a cairo
# surface into sixel format. The escape sequence is used for iTerm2 to control
# size and position of the sixel plot ("gks.six")
# ENV["GKSwstype"] = "six" will create a file gks.six. So, in principle, this
# file could also be rendered in a terminal other than iTerm2 (with sixel support)

import Base: display
display(d::TerminalGraphics.SixelDisplay, plt::Plots.Plot) = begin
    # define a temporary filename and plot to it
    fn = tempname() * ".png"
    isfile(fn) &&
        error("The intended temporary file '$fn' already exists. Try again.")
    open(fn, "w") do io
        show(io, MIME("image/png"), plt)
    end
    # draw the 'png'
    title = string(plt)
    size = string(get(plt.attr, :size, ""))
    size = length(size) == 0 ? "unspecified size" : "size $size"
    println(d.io, "Drawing $title of $size ($fn)")
    TerminalGraphics.draw(d.io, fn)
    # delete the 'png'
    isfile(fn) && Base.Filesystem.rm(fn)
    isfile(fn) &&
        warn("The temporary file '$fn' couldn't be deleted. Please inspect.")
end


#=--- end of file ---------------------------------------------------------=#
