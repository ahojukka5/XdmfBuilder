# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

using BinaryBuilder, Dates, LibGit2

name = "xdmf"
repo = LibGit2.clone("https://gitlab.kitware.com/xdmf/xdmf.git", tempname())
hash_long = string(LibGit2.revparseid(repo, "master"))
build = Dates.format(Dates.now(), "yyyymmdd")
version = VersionNumber("3+$build")

# Collection of sources required to build xdmf
sources = [
    "https://gitlab.kitware.com/xdmf/xdmf.git" =>
    hash_long,

    "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.3/src/hdf5-1.10.3.tar.gz" =>
    "b600d7c914cfa80ae127cd1a1539981213fee9994ac22ebec9e3845e951d9b39",

    "https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.gz" =>
    "96b34f7468f26a141f6020efb813f1a2f3dfb9797ecf76a7d7cbd843cc95f5bd",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd hdf5-1.10.3/
./configure --prefix=$prefix --host=$target
make
make install
cd ..

export BOOST_ROOT=$WORKSPACE/srcdir/boost_1_71_0
cd xdmf
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain -DBUILD_SHARED_LIBS=1
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libXdmf", :libXdmf),
    LibraryProduct(prefix, "libXdmfCore", :libXdmfCore)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	"https://raw.githubusercontent.com/JuliaIO/LightXML.jl/master/deps/build_XML2Builder.v2.9.9.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

