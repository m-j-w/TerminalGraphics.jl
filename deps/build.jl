#=--- TerminalGraphics / deps / build.jl ----------------------------------=#

#=-------------------------------------------------------------------------=#
#
#   Download an build a recent version of 'libsixel'
#
#=-------------------------------------------------------------------------=#

using BinDeps

validate_libsixel(name, handle) = begin
    # try to locate sixel_encoder_encode_bytes, which is only
    # part of the newest, yet un-'released' version, but strictly necessary.
    println("Checking library $name ($handle)")
    try
        Base.Libdl.dlsym(handle, :sixel_encoder_encode_bytes)
        return true
    catch
        #
    end
    false
end

@BinDeps.setup

libsixel = library_dependency( "libsixel", 
                aliases = ["libsixel.so.1.0.6","libsixel.so.1","libsixel.so"],
                validate = validate_libsixel
                )

# build from source
provides(Sources, URI("https://github.com/saitoha/libsixel/archive/master.zip")
                , libsixel
                , unpacked_dir = "libsixel-master")
provides(BuildProcess,
                Autotools(libtarget="src/libsixel.la")
                , libsixel)

@BinDeps.install Dict(:libsixel => :libsixel)


#=--- end of file ---------------------------------------------------------=#
