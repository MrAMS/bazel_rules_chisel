"""Bzlmod extension for Chisel Maven dependencies."""

load("@rules_jvm_external//:defs.bzl", "maven_install")

_DEFAULT_REPOSITORIES = [
    "https://repo1.maven.org/maven2",
    "https://s01.oss.sonatype.org/content/repositories/releases",
]

_DEFAULT_SETTINGS = struct(
    repo_name = "chisel_maven",
    chisel_version = "7.2.0",
    scala_version = "2.13.17",
    firtool_resolver_version = "2.0.1",
    scalatest_version = "3.2.19",
    repositories = _DEFAULT_REPOSITORIES,
    fetch_sources = True,
)

def _scala_short(scala_version):
    parts = scala_version.split(".")
    if len(parts) < 2:
        fail("scala_version must be MAJOR.MINOR.PATCH, got '{}'".format(scala_version))
    return "{}.{}".format(parts[0], parts[1])

def _maven_target(group, artifact):
    return "{}_{}".format(group, artifact).replace(".", "_").replace("-", "_")

def _chisel_alias_repo_impl(repository_ctx):
    scala_short = _scala_short(repository_ctx.attr.scala_version)

    chisel_target = _maven_target("org.chipsalliance", "chisel_{}".format(scala_short))
    firtool_resolver_target = _maven_target("org.chipsalliance", "firtool-resolver_{}".format(scala_short))
    chisel_plugin_target = _maven_target("org.chipsalliance", "chisel-plugin_{}".format(repository_ctx.attr.scala_version))
    scalatest_target = _maven_target("org.scalatest", "scalatest_{}".format(scala_short))

    repository_ctx.file(
        "BUILD.bazel",
        content = """package(default_visibility = ["//visibility:public"])

alias(
    name = "chisel",
    actual = "@{repo}//:{chisel_target}",
)

alias(
    name = "firtool_resolver",
    actual = "@{repo}//:{firtool_resolver_target}",
)

alias(
    name = "chisel_plugin",
    actual = "@{repo}//:{chisel_plugin_target}",
)

alias(
    name = "scalatest",
    actual = "@{repo}//:{scalatest_target}",
)

""".format(
            repo = repository_ctx.attr.internal_repo_name,
            chisel_target = chisel_target,
            firtool_resolver_target = firtool_resolver_target,
            chisel_plugin_target = chisel_plugin_target,
            scalatest_target = scalatest_target,
        ),
    )

_chisel_alias_repo = repository_rule(
    implementation = _chisel_alias_repo_impl,
    attrs = {
        "internal_repo_name": attr.string(mandatory = True),
        "scala_version": attr.string(mandatory = True),
    },
)

def _collect_settings(module_ctx):
    root_tags = []
    fallback_tags = []

    for mod in module_ctx.modules:
        tags = list(mod.tags.toolchain)
        if not tags:
            continue
        if hasattr(mod, "is_root") and mod.is_root:
            root_tags.extend(tags)
        else:
            fallback_tags.extend(tags)

    if len(root_tags) > 1:
        fail("Only one chisel.toolchain(...) tag is allowed in the root module")
    if root_tags:
        return root_tags[0]

    if len(fallback_tags) > 1:
        fail("Only one chisel.toolchain(...) tag is allowed")
    if fallback_tags:
        return fallback_tags[0]

    return _DEFAULT_SETTINGS

def _chisel_extension_impl(module_ctx):
    settings = _collect_settings(module_ctx)
    scala_short = _scala_short(settings.scala_version)

    internal_repo_name = settings.repo_name + "_internal"

    artifacts = [
        "org.chipsalliance:chisel_{}:{}".format(scala_short, settings.chisel_version),
        "org.chipsalliance:chisel-plugin_{}:{}".format(settings.scala_version, settings.chisel_version),
        "org.chipsalliance:firtool-resolver_{}:{}".format(scala_short, settings.firtool_resolver_version),
        "org.scalatest:scalatest_{}:{}".format(scala_short, settings.scalatest_version),
    ]

    maven_install(
        name = internal_repo_name,
        artifacts = artifacts,
        repositories = settings.repositories,
        fetch_sources = settings.fetch_sources,
    )

    _chisel_alias_repo(
        name = settings.repo_name,
        internal_repo_name = internal_repo_name,
        scala_version = settings.scala_version,
    )

    return module_ctx.extension_metadata(
        reproducible = False,
        root_module_direct_deps = [settings.repo_name],
        root_module_direct_dev_deps = [],
    )

toolchain = tag_class(
    attrs = {
        "chisel_version": attr.string(default = _DEFAULT_SETTINGS.chisel_version),
        "fetch_sources": attr.bool(default = _DEFAULT_SETTINGS.fetch_sources),
        "firtool_resolver_version": attr.string(default = _DEFAULT_SETTINGS.firtool_resolver_version),
        "repo_name": attr.string(default = _DEFAULT_SETTINGS.repo_name),
        "repositories": attr.string_list(default = _DEFAULT_SETTINGS.repositories),
        "scala_version": attr.string(default = _DEFAULT_SETTINGS.scala_version),
        "scalatest_version": attr.string(default = _DEFAULT_SETTINGS.scalatest_version),
    },
)

chisel = module_extension(
    implementation = _chisel_extension_impl,
    tag_classes = {"toolchain": toolchain},
)
