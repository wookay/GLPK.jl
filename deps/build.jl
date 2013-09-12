using BinDeps

@BinDeps.setup

toolvers = "2.4.2"
glpkvers = "4.48"
glpkname = "glpk-$glpkvers"


glpkvalidate(name, handle) = bytestring(ccall(dlsym(handle, :glp_version), Ptr{Uint8}, ())) == glpkvers

tooldep = library_dependency("libltdl", os = :Unix)
glpkdep = library_dependency("libglpk", depends = [tooldep], validate = glpkvalidate)

provides(Sources, {URI("ftp://ftp.gnu.org/gnu/libtool/libtool-$toolvers.tar.gz") => tooldep}, os = :Unix)

provides(Sources, {URI("http://ftp.gnu.org/gnu/glpk/$glpkname.tar.gz") => glpkdep}, os = :Unix)
provides(Sources, {URI("http://downloads.sourceforge.net/project/winglpk/winglpk/GLPK-$glpkvers/win$glpkname.zip") => glpkdep}, os = :Windows)

@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    else
        using Homebrew
        provides(Homebrew.HB, "glpk", [tooldep, glpkdep], os = :Darwin)
    end
end

julia_usrdir = normpath("$JULIA_HOME/../") # This is a stopgap, we need a better builtin solution to get the included libraries
libdirs = String["$(julia_usrdir)/lib"]
includedirs = String["$(julia_usrdir)/include"]

provides(AptGet, {"libltdl-dev" => tooldep})

provides(BuildProcess, {
    Autotools(libtarget = joinpath("libltdl", ".libs", "libltdl.la")) => tooldep,
    Autotools(libtarget = joinpath("src", ".libs", "libglpk.la"),
              configure_options = String["--with-gmp", "--enable-dl"],
              #configure_options = String["--with-gmp"],
              lib_dirs = libdirs,
              include_dirs = includedirs) => glpkdep
    }, os = :Unix)

@BinDeps.install
