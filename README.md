# rules_chisel

Bazel rules for Chisel projects with Bzlmod support.

This repository packages the following helpers as a BCR-friendly module:

- `chisel_binary`
- `chisel_library`
- `chisel_test`
- `verilog_single_file_library`

## Features

- One extension (`chisel.toolchain`) to fetch Chisel/ScalaTest Maven artifacts.
- Ready-to-use macro defaults via `@chisel_maven` aliases (`:chisel`, `:chisel_plugin`, etc.).
- Built-in Verilator runtime wrapper in `chisel_test` for BCR Verilator layout quirks.
- Minimal smoke tests and GitHub CI workflows.

## Installation (Bzlmod)

Add this to your `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_chisel", version = "0.1.0")

# rules_chisel uses rules_scala underneath.
bazel_dep(name = "rules_scala", version = "7.1.5")

# Required: configure Scala toolchain yourself.
# rules_chisel intentionally does NOT auto-register Scala toolchains.
scala_config = use_extension("@rules_scala//scala/extensions:config.bzl", "scala_config")
scala_config.settings(scala_version = "2.13.17")
use_repo(scala_config, "rules_scala_config")

scala_deps = use_extension("@rules_scala//scala/extensions:deps.bzl", "scala_deps")
scala_deps.scala()
scala_deps.scalatest()  # needed by chisel_test (scala_test toolchain)
use_repo(
    scala_deps,
    "io_bazel_rules_scala_scala_compiler",
    "io_bazel_rules_scala_scala_library",
    "io_bazel_rules_scala_scala_reflect",
    "io_bazel_rules_scala_scalactic",
    "io_bazel_rules_scala_scalatest",
    "io_bazel_rules_scala_scalatest_compatible",
    "io_bazel_rules_scala_scalatest_core",
    "io_bazel_rules_scala_scalatest_diagrams",
    "io_bazel_rules_scala_scalatest_featurespec",
    "io_bazel_rules_scala_scalatest_flatspec",
    "io_bazel_rules_scala_scalatest_freespec",
    "io_bazel_rules_scala_scalatest_funspec",
    "io_bazel_rules_scala_scalatest_funsuite",
    "io_bazel_rules_scala_scalatest_matchers_core",
    "io_bazel_rules_scala_scalatest_mustmatchers",
    "io_bazel_rules_scala_scalatest_propspec",
    "io_bazel_rules_scala_scalatest_refspec",
    "io_bazel_rules_scala_scalatest_shouldmatchers",
    "io_bazel_rules_scala_scalatest_wordspec",
    "rules_scala_toolchains",
)
register_toolchains("@rules_scala_toolchains//...:all")

# Required for chisel_test: Verilator runtime/tools.
bazel_dep(name = "verilator", version = "5.036.bcr.3")

# Chisel dependencies (creates @chisel_maven)
chisel = use_extension("@rules_chisel//chisel:extensions.bzl", "chisel")
chisel.toolchain(
    chisel_version = "7.2.0",
    scala_version = "2.13.17", # should match rules_scala's scala_version
    firtool_resolver_version = "2.0.1",  # should match the selected Chisel version
)
use_repo(chisel, "chisel_maven")
```


## Notes

- Scala toolchain setup is **mandatory** in your own `MODULE.bazel`. This is by design: `rules_chisel` leaves Scala version/toolchain control to users.
- `chisel_test` wraps `scala_test` and sets up a Verilator runtime environment. It expects `@verilator//:bin/verilator` and `@verilator//:verilator_includes`. If you don't use `chisel_test`, you can skip the Verilator dependency.
- Please explicitly set `firtool_resolver_version` in `chisel.toolchain(...)`. It is tightly coupled with `chisel_version`. See [Chisel Project Versioning](https://www.chisel-lang.org/docs/appendix/versioning)

## Usage

You can check `tests` for examples as well.

```starlark
load("@rules_chisel//chisel:defs.bzl", "chisel_binary", "chisel_library", "chisel_test")
load("@rules_chisel//verilog:defs.bzl", "verilog_single_file_library")

chisel_library(
    name = "adder_lib",
    srcs = ["Adder.scala"],
)

chisel_binary(
    name = "emit_adder",
    srcs = ["EmitAdder.scala"],
    deps = [":adder_lib"],
    main_class = "demo.EmitAdder",
)

chisel_test(
    name = "adder_test",
    srcs = ["AdderTest.scala"],
    deps = [":adder_lib"],
)

verilog_single_file_library(
    name = "merged_sv",
    srcs = [
        "foo.sv",
        "bar.v",
        "README.txt",  # ignored by rule
    ],
)
```

## Chisel Extension Options

`chisel.toolchain(...)` supports:

- `repo_name` (default: `"chisel_maven"`)
- `chisel_version` (default: `"7.2.0"`)
- `scala_version` (default: `"2.13.17"`)
- `firtool_resolver_version` (it must match `chisel_version`, see [Chisel Project Versioning](https://www.chisel-lang.org/docs/appendix/versioning))
- `scalatest_version` (default: `"3.2.19"`)
- `repositories` (default: Maven Central + Sonatype releases)
- `fetch_sources` (default: `True`)

If you change `repo_name`, pass the same repo to macros via `deps_repo`:

```starlark
chisel_library(
    name = "my_lib",
    srcs = ["My.scala"],
    deps_repo = "my_chisel_repo",
)
```

## Development

Local smoke targets:

```bash
bazel build //...
bazel test //tests/smoke:verilog_concat_test
bazel test //tests/smoke:simple_adder_test --test_output=errors
tests/version_compat/check_chisel_versions.sh
```

## License

Apache 2.0.
