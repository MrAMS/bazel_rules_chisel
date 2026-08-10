"""Repository rule to fetch OS-specific circt binaries."""

def _circt_repo_impl(ctx):
    os_name = ctx.os.name.lower()
    if os_name.startswith("mac"):
        url = "https://github.com/llvm/circt/releases/download/firtool-1.137.0/circt-full-static-macos-x64.tar.gz"
        sha256 = "225578a949893835b660939947d9f78db404ba61e17148601f7ee6fdf5f887dc"
    elif "windows" in os_name:
        url = "https://github.com/llvm/circt/releases/download/firtool-1.137.0/circt-full-static-windows-x64.zip"
        sha256 = ""  # Omit sha256 for Windows for now
    else:
        url = "https://github.com/llvm/circt/releases/download/firtool-1.137.0/circt-full-static-linux-x64.tar.gz"
        sha256 = "c00d58b93c9d7ad13f0e95e78cef180a5dfb9a416cd11a2dd7814fdbe4132439"

    kwargs = {
        "stripPrefix": "firtool-1.137.0",
        "url": url,
    }
    if sha256:
        kwargs["sha256"] = sha256

    ctx.download_and_extract(**kwargs)

    ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

exports_files(["bin/firtool", "bin/firtool.exe"])
""")

circt_repo = repository_rule(
    implementation = _circt_repo_impl,
)
