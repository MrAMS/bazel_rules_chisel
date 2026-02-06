package smoke

import org.scalatest.funsuite.AnyFunSuite

class SimpleAdderTest extends AnyFunSuite {
  test("sanity") {
    assert(2 + 2 == 4)
  }
}
