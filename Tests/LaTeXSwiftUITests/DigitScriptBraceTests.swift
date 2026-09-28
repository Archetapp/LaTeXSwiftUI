import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("insertSpaceBeforeDigitScriptBrace")
struct DigitScriptBraceTests {
    func f(_ s: String) -> String { Renderer.insertSpaceBeforeDigitScriptBrace(s) }

    @Test("superscript ending in digit gets a space")
    func superscriptDigit() {
        #expect(f("x^{n+1}") == "x^{n+1 }")
        #expect(f("(1 - x)(1 + x + \\cdots + x^n) = 1 - x^{n+1}")
                == "(1 - x)(1 + x + \\cdots + x^n) = 1 - x^{n+1 }")
        #expect(f("x_{12}") == "x_{12 }")
    }

    @Test("superscript ending in non-digit unchanged")
    func superscriptNonDigit() {
        #expect(f("x^{n}") == "x^{n}")
        #expect(f("x^{n+a}") == "x^{n+a}")
    }

    @Test("non-script braces untouched (hex colors safe)")
    func nonScriptBraces() {
        #expect(f("\\textcolor{#ff3b30}{x}") == "\\textcolor{#ff3b30}{x}")
        #expect(f("\\textcolor{#374151}{1 - 2 ^4 = 1 - 16 = \\textcolor{#ff3b30}{-15}}")
                == "\\textcolor{#374151}{1 - 2 ^4 = 1 - 16 = \\textcolor{#ff3b30}{-15}}")
        #expect(f("\\mathbf{1 - x^5}") == "\\mathbf{1 - x^5}")
    }

    @Test("nested frac inside script not double-spaced")
    func nestedFrac() {
        #expect(f("3^{\\frac{t}{4}}") == "3^{\\frac{t}{4}}")
        #expect(f("x^{y^{2}}") == "x^{y^{2 }}")
    }

    @Test("no braces unchanged")
    func noBraces() {
        #expect(f("x^2 + y^2 = 1") == "x^2 + y^2 = 1")
        #expect(f("a + b") == "a + b")
    }
}
