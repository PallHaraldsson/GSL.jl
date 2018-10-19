using BinaryProvider # requires BinaryProvider 0.3.0 or later
using Compat

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    # work around for https://github.com/JuliaPackaging/BinaryProvider.jl/issues/133
    LibraryProduct(prefix, [Compat.Sys.iswindows() ? "libgsl" : "libgsl."], :libgsl),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/giordano/GSLBuilder.jl/releases/download/v1.16"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, :glibc) => ("$bin_prefix/GSL.v1.16.0.aarch64-linux-gnu.tar.gz", "e8634da5d16f46708c6fbe25af8759d9dabec8cbacad742e7ff4b50899ea212a"),
    Linux(:aarch64, :musl) => ("$bin_prefix/GSL.v1.16.0.aarch64-linux-musl.tar.gz", "b0ba1bfd7f1ae49ed0a8afd0674c8e25612816fae33c4119e99dfde02f9021a5"),
    Linux(:armv7l, :glibc, :eabihf) => ("$bin_prefix/GSL.v1.16.0.arm-linux-gnueabihf.tar.gz", "7e33f9a43a9c249dde281c3e4faefb3a92921c6a6e26dd6a1a44a3de0bd67240"),
    Linux(:armv7l, :musl, :eabihf) => ("$bin_prefix/GSL.v1.16.0.arm-linux-musleabihf.tar.gz", "6ccd2b1cebb218c655930ac5c406dc9266cdb40156398de98b162f059905c421"),
    Linux(:i686, :glibc) => ("$bin_prefix/GSL.v1.16.0.i686-linux-gnu.tar.gz", "43c6e117ad6497abe06a8decc606be2ec1e405a404a389bc8f08c24181c769d4"),
    Linux(:i686, :musl) => ("$bin_prefix/GSL.v1.16.0.i686-linux-musl.tar.gz", "3132c7741ff8f13d482fc7552edd3d8e4969e30675431ac9c328006ceefb7e6b"),
    Windows(:i686) => ("$bin_prefix/GSL.v1.16.0.i686-w64-mingw32.tar.gz", "fae91bcdab5cb61b03b3d409a637cc6dfa012ae15213f944cdefc35ff087a63c"),
    Linux(:powerpc64le, :glibc) => ("$bin_prefix/GSL.v1.16.0.powerpc64le-linux-gnu.tar.gz", "c15a8526ee7ea31f863e2298eda1ff7854944b33f215e04d6507b1b6a9813bd9"),
    MacOS(:x86_64) => ("$bin_prefix/GSL.v1.16.0.x86_64-apple-darwin14.tar.gz", "ac61865e6c90251475e99307cfa0b5212f91b2e5981334fdeac1da8fca87516a"),
    Linux(:x86_64, :glibc) => ("$bin_prefix/GSL.v1.16.0.x86_64-linux-gnu.tar.gz", "c3e11b617834ad825e45c8d4b5df487de5d3c337cdd0c095e75760412517e499"),
    Linux(:x86_64, :musl) => ("$bin_prefix/GSL.v1.16.0.x86_64-linux-musl.tar.gz", "721dd18177de6c137f84713cc8b7e89dda06dd7e137ad12364c26fcd1d686add"),
    FreeBSD(:x86_64) => ("$bin_prefix/GSL.v1.16.0.x86_64-unknown-freebsd11.1.tar.gz", "92aaa6a2952fe19011579993a22f9a1fcd000b27f72aaa7e7459f1fee97e6b90"),
    Windows(:x86_64) => ("$bin_prefix/GSL.v1.16.0.x86_64-w64-mingw32.tar.gz", "11db5c987a92abbcc0bee936a6c616d4fa51c9e74931ef166107d85ace44b4d8"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
if haskey(download_info, platform_key())
    url, tarball_hash = download_info[platform_key()]
    if unsatisfied || !isinstalled(url, tarball_hash; prefix=prefix)
        # Download and install binaries
        install(url, tarball_hash; prefix=prefix, force=true, verbose=verbose)
    end
elseif unsatisfied
    # If we don't have a BinaryProvider-compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform $(triplet(platform_key())) is not supported by this package!")
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
