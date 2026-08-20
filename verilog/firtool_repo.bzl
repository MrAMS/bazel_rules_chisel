"""Prepares a native firtool using Chisel's firtool-resolver."""

def _maven_urls(repositories, group, artifact, version):
    relative_path = "{group_path}/{artifact}/{version}/{artifact}-{version}.jar".format(
        group_path = group.replace(".", "/"),
        artifact = artifact,
        version = version,
    )
    return [repository.rstrip("/") + "/" + relative_path for repository in repositories]

def _download_jar(ctx, group, artifact, version, output):
    ctx.download(
        canonical_id = "{}:{}:{}".format(group, artifact, version),
        output = output,
        url = _maven_urls(ctx.attr.repositories, group, artifact, version),
    )

def _firtool_repo_impl(ctx):
    scala_short = ".".join(ctx.attr.scala_version.split(".")[:2])
    bootstrap_dir = "_resolver_bootstrap"
    chisel_jar = bootstrap_dir + "/chisel.jar"
    collection_compat_jar = bootstrap_dir + "/scala-collection-compat.jar"
    resolver_jar = bootstrap_dir + "/firtool-resolver.jar"
    scala_jar = bootstrap_dir + "/scala-library.jar"
    scala_xml_jar = bootstrap_dir + "/scala-xml.jar"

    _download_jar(
        ctx,
        "org.chipsalliance",
        "chisel_{}".format(scala_short),
        ctx.attr.chisel_version,
        chisel_jar,
    )
    _download_jar(
        ctx,
        "org.chipsalliance",
        "firtool-resolver_{}".format(scala_short),
        ctx.attr.firtool_resolver_version,
        resolver_jar,
    )
    _download_jar(
        ctx,
        "org.scala-lang",
        "scala-library",
        ctx.attr.scala_version,
        scala_jar,
    )
    _download_jar(
        ctx,
        "org.scala-lang.modules",
        "scala-collection-compat_{}".format(scala_short),
        "2.11.0",
        collection_compat_jar,
    )
    _download_jar(
        ctx,
        "org.scala-lang.modules",
        "scala-xml_{}".format(scala_short),
        "2.2.0",
        scala_xml_jar,
    )

    java = ctx.which("java")
    if java == None:
        fail("Preparing firtool requires Java 11 or newer on PATH")

    path_separator = ";" if "windows" in ctx.os.name.lower() else ":"
    classpath = path_separator.join([
        str(ctx.path(chisel_jar)),
        str(ctx.path(collection_compat_jar)),
        str(ctx.path(resolver_jar)),
        str(ctx.path(scala_jar)),
        str(ctx.path(scala_xml_jar)),
    ])
    cache_dir = ctx.path(bootstrap_dir + "/cache")
    output = ctx.path("bin/firtool")
    result = ctx.execute(
        [
            java,
            "--class-path",
            classpath,
            ctx.path(ctx.attr._resolver_source),
            output,
        ],
        environment = {
            "CHISEL_FIRTOOL_CACHE": str(cache_dir.get_child("firtool")),
            "COURSIER_CACHE": str(cache_dir.get_child("coursier")),
        },
        quiet = False,
        timeout = 600,
    )
    if result.return_code != 0:
        fail("firtool-resolver failed:\nstdout:\n{}\nstderr:\n{}".format(
            result.stdout,
            result.stderr,
        ))

    # Bootstrap dependencies are not part of the generated repository.
    ctx.delete(bootstrap_dir)
    ctx.file("BUILD.bazel", """package(default_visibility = ["//visibility:public"])

exports_files(["bin/firtool"])
""")

firtool_repo = repository_rule(
    implementation = _firtool_repo_impl,
    attrs = {
        "chisel_version": attr.string(mandatory = True),
        "firtool_resolver_version": attr.string(mandatory = True),
        "repositories": attr.string_list(mandatory = True),
        "scala_version": attr.string(mandatory = True),
        "_resolver_source": attr.label(
            allow_single_file = [".java"],
            default = Label("//verilog:ResolveFirtool.java"),
        ),
    },
)
