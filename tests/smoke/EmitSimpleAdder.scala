package smoke

import java.nio.file.{Files, Paths}

object EmitSimpleAdder {
  def main(args: Array[String]): Unit = {
    // We vendor the MLIR representation here rather than running a full Chisel compilation
    // (e.g. via `ChiselStage.emitCHIRRTL`). This keeps the smoke test extremely fast and lightweight
    // by avoiding circt/JNI dependencies during the Scala execution phase.
    // We emit the MLIR dialect natively because the bazel rules we are testing explicitly 
    // pass `--format=mlir` to firtool.
    val mlir = """module {
  firrtl.circuit "SimpleAdder" {
    firrtl.module @SimpleAdder(in %clock: !firrtl.clock, in %reset: !firrtl.uint<1>, in %a: !firrtl.uint<8>, in %b: !firrtl.uint<8>, out %c: !firrtl.uint<8>) attributes {convention = #firrtl<convention scalarized>} {
      %0 = firrtl.add %a, %b : (!firrtl.uint<8>, !firrtl.uint<8>) -> !firrtl.uint<9>
      %1 = firrtl.tail %0, 1 : (!firrtl.uint<9>) -> !firrtl.uint<8>
      firrtl.matchingconnect %c, %1 : !firrtl.uint<8>
    }
  }
}
"""
    val i = args.indexOf("-o")
    if (i >= 0 && i < args.length - 1) {
      Files.write(Paths.get(args(i + 1)), mlir.getBytes("UTF-8"))
    } else {
      sys.error("Missing -o flag")
    }
  }
}
