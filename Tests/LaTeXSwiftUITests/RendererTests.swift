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
