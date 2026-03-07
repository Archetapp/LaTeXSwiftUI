import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("Parser Block Parsing Tests")
struct ParserBlockTests {

    // MARK: - parse(_:mode:) with .onlyEquations mode

    @Test("Empty input produces empty blocks")
    func emptyInputEmptyBlocks() {
        let blocks = Parser.parse("", mode: .onlyEquations)
        #expect(blocks.count == 0)
    }

    @Test("Plain text produces single block with one text component")
    func plainTextSingleBlock() {
        let blocks = Parser.parse("Hello, World!", mode: .onlyEquations)
        #expect(blocks.count == 1)
        #expect(blocks[0].components.count == 1)
        #expect(blocks[0].components[0].type == .text)
    }

    @Test("Inline equation stays in same block as surrounding text")
    func inlineEquationSameBlock() {
        let blocks = Parser.parse("The equation $x^2$ is simple.", mode: .onlyEquations)
        #expect(blocks.count == 1)
        #expect(blocks[0].components.count == 3)
        #expect(blocks[0].components[0].type == .text)
        #expect(blocks[0].components[1].type == .inlineEquation)
        #expect(blocks[0].components[2].type == .text)
    }

    @Test("Block equation creates separate block")
    func blockEquationSeparateBlock() {
        let blocks = Parser.parse("Before \\[x^2\\] After", mode: .onlyEquations)
        #expect(blocks.count == 3)
        #expect(blocks[0].components[0].type == .text)
        #expect(blocks[0].components[0].text == "Before ")
        #expect(blocks[1].components[0].type == .blockEquation)
        #expect(blocks[1].components[0].text == "x^2")
        #expect(blocks[2].components[0].type == .text)
        #expect(blocks[2].components[0].text == " After")
    }

    @Test("Multiple inline equations in same block")
    func multipleInlineEquationsSameBlock() {
        let blocks = Parser.parse("$a$ and $b$", mode: .onlyEquations)
        #expect(blocks.count == 1)
        #expect(blocks[0].components.count == 3)
    }

    @Test("Mixed inline and block equations")
    func mixedInlineAndBlock() {
        let blocks = Parser.parse("$a$ then \\[b\\] then $c$", mode: .onlyEquations)
        #expect(blocks.count == 3)
        #expect(blocks[0].components.count == 2)
        #expect(blocks[1].isEquationBlock == true)
        #expect(blocks[2].components.count == 2)
    }

    // MARK: - parse(_:mode:) with .all mode

    @Test("All mode wraps entire text as inline equation")
    func allModeWrapsAsInlineEquation() {
        let blocks = Parser.parse("x^2 + y^2 = 1", mode: .all)
        #expect(blocks.count == 1)
        #expect(blocks[0].components.count == 1)
        #expect(blocks[0].components[0].type == .inlineEquation)
        #expect(blocks[0].components[0].text == "x^2 + y^2 = 1")
    }

    @Test("All mode with empty input")
    func allModeEmptyInput() {
        let blocks = Parser.parse("", mode: .all)
        #expect(blocks.count == 1)
        #expect(blocks[0].components.count == 1)
        #expect(blocks[0].components[0].type == .inlineEquation)
        #expect(blocks[0].components[0].text == "")
    }

    // MARK: - Complex Parsing Scenarios

    @Test("Multiple block equations create separate blocks each")
    func multipleBlockEquations() {
        let input = "\\[a\\] \\[b\\]"
        let blocks = Parser.parse(input, mode: .onlyEquations)
        let equationBlocks = blocks.filter { $0.isEquationBlock }
        #expect(equationBlocks.count == 2)
    }

    @Test("Named equation creates equation block")
    func namedEquationBlock() {
        let blocks = Parser.parse("Text \\begin{equation}E=mc^2\\end{equation} more text", mode: .onlyEquations)
        let equationBlocks = blocks.filter { $0.isEquationBlock }
        #expect(equationBlocks.count == 1)
        #expect(equationBlocks[0].components[0].type == .namedEquation)
    }

    @Test("TeX equation (double dollar) creates equation block")
    func texEquationBlock() {
        let blocks = Parser.parse("Before $$E=mc^2$$ After", mode: .onlyEquations)
        let equationBlocks = blocks.filter { $0.isEquationBlock }
        #expect(equationBlocks.count == 1)
        #expect(equationBlocks[0].components[0].type == .texEquation)
    }

    @Test("Text-only input produces no equation blocks")
    func textOnlyNoEquationBlocks() {
        let blocks = Parser.parse("Just some text.", mode: .onlyEquations)
        let equationBlocks = blocks.filter { $0.isEquationBlock }
        #expect(equationBlocks.count == 0)
    }

    // MARK: - Edge Cases in Component Parsing

    @Test("Adjacent equations with space separator are parsed separately")
    func adjacentEquations() {
        let components = Parser.parse("$a$ $b$")
        #expect(components.count == 3)
        #expect(components[0].text == "a")
        #expect(components[0].type == .inlineEquation)
        #expect(components[1].text == " ")
        #expect(components[1].type == .text)
        #expect(components[2].text == "b")
        #expect(components[2].type == .inlineEquation)
    }

    @Test("Equation at start of string")
    func equationAtStart() {
        let components = Parser.parse("$x$ is a variable")
        #expect(components.count == 2)
        #expect(components[0].type == .inlineEquation)
        #expect(components[1].type == .text)
    }

    @Test("Equation at end of string")
    func equationAtEnd() {
        let components = Parser.parse("The result is $42$")
        #expect(components.count == 2)
        #expect(components[0].type == .text)
        #expect(components[1].type == .inlineEquation)
    }

    @Test("Only whitespace text parses as text component")
    func whitespaceOnlyText() {
        let components = Parser.parse("   ")
        #expect(components.count == 1)
        #expect(components[0].type == .text)
        #expect(components[0].text == "   ")
    }

    @Test("Nested begin/end environments parse outer only")
    func nestedBeginEnd() {
        let input = "\\begin{equation}a + \\begin{equation}b\\end{equation}\\end{equation}"
        let components = Parser.parse(input)
        #expect(components.count >= 1)
    }

    @Test("Multiple different equation types in one string")
    func multipleDifferentEquationTypes() {
        let input = "Inline $a$ and block \\[b\\] and named \\begin{equation}c\\end{equation}"
        let components = Parser.parse(input)
        let types = components.map { $0.type }
        #expect(types.contains(.inlineEquation))
        #expect(types.contains(.blockEquation))
        #expect(types.contains(.namedEquation))
    }
}
