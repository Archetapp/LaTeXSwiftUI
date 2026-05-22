import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("Renderer Tests")
struct RendererTests {

    // MARK: - ParsingSource Equatable

    @Test("ParsingSource equality for identical values")
    func parsingSourceEquality() {
        let a = Renderer.ParsingSource(latex: "$x$", unencodeHTML: false, parsingMode: .onlyEquations)
        let b = Renderer.ParsingSource(latex: "$x$", unencodeHTML: false, parsingMode: .onlyEquations)
        #expect(a == b)
    }

    @Test("ParsingSource inequality when latex differs")
    func parsingSourceInequalityLatex() {
        let a = Renderer.ParsingSource(latex: "$x$", unencodeHTML: false, parsingMode: .onlyEquations)
        let b = Renderer.ParsingSource(latex: "$y$", unencodeHTML: false, parsingMode: .onlyEquations)
        #expect(a != b)
    }

    @Test("ParsingSource inequality when unencodeHTML differs")
    func parsingSourceInequalityHTML() {
        let a = Renderer.ParsingSource(latex: "$x$", unencodeHTML: false, parsingMode: .onlyEquations)
        let b = Renderer.ParsingSource(latex: "$x$", unencodeHTML: true, parsingMode: .onlyEquations)
        #expect(a != b)
    }

    @Test("ParsingSource inequality when parsingMode differs")
    func parsingSourceInequalityMode() {
        let a = Renderer.ParsingSource(latex: "$x$", unencodeHTML: false, parsingMode: .onlyEquations)
        let b = Renderer.ParsingSource(latex: "$x$", unencodeHTML: false, parsingMode: .all)
        #expect(a != b)
    }

    // MARK: - RenderingError

    @Test("RenderingError cases exist")
    func renderingErrorCases() {
        let errors: [Renderer.RenderingError] = [
            .svgGenerationFailed,
            .imageGenerationFailed,
            .mathJaxUnavailable,
            .cacheCorrupted
        ]
        #expect(errors.count == 4)
    }

    // MARK: - parseBlocks

    @Test("parseBlocks returns parsed blocks for simple text")
    func parseBlocksSimpleText() {
        let renderer = Renderer()
        let blocks = renderer.parseBlocks(latex: "Hello", unencodeHTML: false, parsingMode: .onlyEquations)
        #expect(blocks.count >= 1)
    }

    @Test("parseBlocks returns parsed blocks for equation")
    func parseBlocksEquation() {
        let renderer = Renderer()
        let blocks = renderer.parseBlocks(latex: "$x^2$", unencodeHTML: false, parsingMode: .onlyEquations)
        #expect(blocks.count >= 1)
    }

    @Test("numeric-base exponent normalization adds harmless TeX spacing")
    func normalizeNumericBaseExponentsForMathJax() {
        #expect(Renderer.normalizeNumericBaseExponentsForMathJax("3^4") == "3 ^4")
        #expect(Renderer.normalizeNumericBaseExponentsForMathJax("3^{t/4}") == "3 ^{t/4}")
        #expect(
            Renderer.normalizeNumericBaseExponentsForMathJax("B(t) = 500 \\cdot 3^{\\frac{t}{4}}")
                == "B(t) = 500 \\cdot 3 ^{\\frac{t}{4}}"
        )
        #expect(
            Renderer.normalizeNumericBaseExponentsForMathJax("x^2 + (3)^2 + 3 ^2")
                == "x^2 + (3)^2 + 3 ^2"
        )
        #expect(
            Renderer.normalizeNumericBaseExponentsForMathJax("\\text{3^4} + 3^4")
                == "\\text{3^4} + 3 ^4"
        )
    }

    @Test("renderSync renders numeric-base exponents")
    @MainActor func renderSyncNumericBaseExponents() {
        for latex in [
            "$$3^4$$",
            "$$3^{t/4}$$",
            "$$B(t) = 500 \\cdot 3^{\\frac{t}{4}}$$",
            "$$= 500 \\cdot 3^1$$"
        ] {
            let renderer = Renderer()
            let blocks = renderer.renderSync(
                latex: latex,
                unencodeHTML: false,
                parsingMode: .onlyEquations,
                processEscapes: false,
                errorMode: .original,
                xHeight: 8,
                displayScale: 2,
                renderingMode: .template
            )

            let equations = blocks.flatMap(\.components).filter { $0.type.isEquation }
            #expect(equations.count == 1)
            #expect(equations.first?.svg != nil)
            #expect(equations.first?.svg?.errorText == nil)
            #expect(equations.first?.imageContainer != nil)
        }
    }

    @Test("renderSync renders sqrt inline equation")
    @MainActor func renderSyncSqrtInlineEquation() {
        let renderer = Renderer()
        let blocks = renderer.renderSync(
            latex: "$7\\sqrt{6}$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8,
            displayScale: 2,
            renderingMode: .template
        )

        let equations = blocks.flatMap(\.components).filter { $0.type.isEquation }
        #expect(equations.count == 1)
        #expect(equations.first?.svg != nil)
        #expect(equations.first?.svg?.errorText == nil)
        #expect(equations.first?.imageContainer != nil)
    }

    @Test("renderSync renders textcolor with sqrt inline equation")
    @MainActor func renderSyncTextcolorSqrtInlineEquation() {
        let renderer = Renderer()
        let blocks = renderer.renderSync(
            latex: "$\\textcolor{#007AFF}{7}\\sqrt{5}$",
            unencodeHTML: false,
            parsingMode: .onlyEquations,
            processEscapes: false,
            errorMode: .original,
            xHeight: 8,
            displayScale: 2,
            renderingMode: .template
        )

        let equations = blocks.flatMap(\.components).filter { $0.type.isEquation }
        #expect(equations.count == 1)
        #expect(equations.first?.svg != nil)
        #expect(equations.first?.svg?.errorText == nil)
        #expect(equations.first?.imageContainer != nil)
    }

    @Test("parseBlocks with all mode wraps as equation")
    func parseBlocksAllMode() {
        let renderer = Renderer()
        let blocks = renderer.parseBlocks(latex: "x^2", unencodeHTML: false, parsingMode: .all)
        #expect(blocks.count == 1)
        #expect(blocks[0].components.first?.type == .inlineEquation)
    }

    @Test("parseBlocks caches result for same input")
    func parseBlocksCaching() {
        let renderer = Renderer()
        let blocks1 = renderer.parseBlocks(latex: "$test$", unencodeHTML: false, parsingMode: .onlyEquations)
        let blocks2 = renderer.parseBlocks(latex: "$test$", unencodeHTML: false, parsingMode: .onlyEquations)
        #expect(blocks1.count == blocks2.count)
    }

    @Test("parseBlocks returns different result for different input")
    func parseBlocksDifferentInput() {
        let renderer = Renderer()
        let blocks1 = renderer.parseBlocks(latex: "$x$", unencodeHTML: false, parsingMode: .onlyEquations)
        let blocks2 = renderer.parseBlocks(latex: "No equations here", unencodeHTML: false, parsingMode: .onlyEquations)
        let hasEquation1 = blocks1.flatMap { $0.components }.contains { $0.type.isEquation }
        let hasEquation2 = blocks2.flatMap { $0.components }.contains { $0.type.isEquation }
        #expect(hasEquation1 == true)
        #expect(hasEquation2 == false)
    }

    @Test("parseBlocks for empty string returns empty blocks")
    func parseBlocksEmpty() {
        let renderer = Renderer()
        let blocks = renderer.parseBlocks(latex: "", unencodeHTML: false, parsingMode: .onlyEquations)
        #expect(blocks.isEmpty)
    }

    // MARK: - Renderer State

    @Test("Renderer initial state is not rendered")
    @MainActor func initialStateNotRendered() {
        let renderer = Renderer()
        #expect(renderer.rendered == false)
        #expect(renderer.syncRendered == false)
        #expect(renderer.isRendering == false)
        #expect(renderer.blocks.isEmpty)
    }

    @Test("invalidateRenderState resets all state")
    @MainActor func invalidateRenderState() {
        let renderer = Renderer()
        renderer.rendered = true
        renderer.syncRendered = true
        renderer.blocks = [ComponentBlock(components: [Component(text: "x", type: .text)])]

        renderer.invalidateRenderState()

        #expect(renderer.rendered == false)
        #expect(renderer.syncRendered == false)
        #expect(renderer.isRendering == false)
        #expect(renderer.blocks.isEmpty)
    }
}
