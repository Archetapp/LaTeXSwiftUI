import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("LaTeX Configuration Tests")
struct ConfigurationTests {

    // MARK: - BlockMode

    @Test("BlockMode has three cases")
    func blockModeCases() {
        let modes: [LaTeX.BlockMode] = [.alwaysInline, .blockText, .blockViews]
        #expect(modes.count == 3)
    }

    // MARK: - EquationNumberMode

    @Test("EquationNumberMode has three cases")
    func equationNumberModeCases() {
        let modes: [LaTeX.EquationNumberMode] = [.none, .left, .right]
        #expect(modes.count == 3)
    }

    // MARK: - ErrorMode

    @Test("ErrorMode has three cases")
    func errorModeCases() {
        let modes: [LaTeX.ErrorMode] = [.rendered, .original, .error]
        #expect(modes.count == 3)
    }

    // MARK: - ParsingMode

    @Test("ParsingMode has two cases")
    func parsingModeCases() {
        let modes: [LaTeX.ParsingMode] = [.all, .onlyEquations]
        #expect(modes.count == 2)
    }

    // MARK: - RenderingStyle

    @Test("RenderingStyle has five cases")
    func renderingStyleCases() {
        let styles: [LaTeX.RenderingStyle] = [.empty, .original, .redactedOriginal, .progress, .wait]
        #expect(styles.count == 5)
    }

    // MARK: - BlockAlignment

    @Test("BlockAlignment has three cases")
    func blockAlignmentCases() {
        let alignments: [LaTeX.BlockAlignment] = [.leading, .center, .trailing]
        #expect(alignments.count == 3)
    }

    // MARK: - ConfigurationDefaults

    @Test("Default display scale is 2.0")
    func defaultDisplayScale() {
        #expect(LaTeX.ConfigurationDefaults.displayScale == 2.0)
    }

    // MARK: - RenderInvalidationKey

    @Test("RenderInvalidationKey equality for identical values")
    func renderInvalidationKeyEquality() {
        let key1 = LaTeX.RenderInvalidationKey(
            latex: "$x^2$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        let key2 = LaTeX.RenderInvalidationKey(
            latex: "$x^2$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        #expect(key1 == key2)
    }

    @Test("RenderInvalidationKey inequality when latex differs")
    func renderInvalidationKeyInequalityLatex() {
        let key1 = LaTeX.RenderInvalidationKey(
            latex: "$x^2$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        let key2 = LaTeX.RenderInvalidationKey(
            latex: "$y^2$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        #expect(key1 != key2)
    }

    @Test("RenderInvalidationKey inequality when unencodeHTML differs")
    func renderInvalidationKeyInequalityHTML() {
        let key1 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        let key2 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: true,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        #expect(key1 != key2)
    }

    @Test("RenderInvalidationKey inequality when parsingMode differs")
    func renderInvalidationKeyInequalityParsingMode() {
        let key1 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        let key2 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: false,
            parsingMode: .all,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        #expect(key1 != key2)
    }

    @Test("RenderInvalidationKey inequality when xHeight differs")
    func renderInvalidationKeyInequalityXHeight() {
        let key1 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        let key2 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 10.0,
            displayScale: 2.0
        )
        #expect(key1 != key2)
    }

    @Test("RenderInvalidationKey inequality when displayScale differs")
    func renderInvalidationKeyInequalityDisplayScale() {
        let key1 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 2.0
        )
        let key2 = LaTeX.RenderInvalidationKey(
            latex: "$x$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8.0,
            displayScale: 3.0
        )
        #expect(key1 != key2)
    }
}
