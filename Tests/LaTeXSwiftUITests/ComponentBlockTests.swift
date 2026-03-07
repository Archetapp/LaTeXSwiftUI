import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("ComponentBlock Tests")
struct ComponentBlockTests {

    // MARK: - isEquationBlock

    @Test("Single non-inline component marks block as equation block")
    func singleBlockEquationIsEquationBlock() {
        let component = Component(text: "x^2", type: .blockEquation)
        let block = ComponentBlock(components: [component])
        #expect(block.isEquationBlock == true)
    }

    @Test("Single inline component is not an equation block")
    func singleInlineComponentIsNotEquationBlock() {
        let component = Component(text: "x^2", type: .inlineEquation)
        let block = ComponentBlock(components: [component])
        #expect(block.isEquationBlock == false)
    }

    @Test("Single text component is not an equation block")
    func singleTextComponentIsNotEquationBlock() {
        let component = Component(text: "Hello", type: .text)
        let block = ComponentBlock(components: [component])
        #expect(block.isEquationBlock == false)
    }

    @Test("Multiple components is not an equation block")
    func multipleComponentsIsNotEquationBlock() {
        let components = [
            Component(text: "Hello ", type: .text),
            Component(text: "x^2", type: .blockEquation)
        ]
        let block = ComponentBlock(components: components)
        #expect(block.isEquationBlock == false)
    }

    @Test("Empty block is not an equation block")
    func emptyBlockIsNotEquationBlock() {
        let block = ComponentBlock(components: [])
        #expect(block.isEquationBlock == false)
    }

    // MARK: - SVG and Container Properties

    @Test("SVG returns first component SVG")
    func svgReturnsFirstComponentSVG() {
        let component = Component(text: "x", type: .text, svg: nil)
        let block = ComponentBlock(components: [component])
        #expect(block.svg == nil)
    }

    @Test("Container returns first component imageContainer")
    func containerReturnsFirstComponentImageContainer() {
        let component = Component(text: "x", type: .text, imageContainer: nil)
        let block = ComponentBlock(components: [component])
        #expect(block.container == nil)
    }

    @Test("Empty block returns nil for svg")
    func emptyBlockSVGIsNil() {
        let block = ComponentBlock(components: [])
        #expect(block.svg == nil)
    }

    @Test("Empty block returns nil for container")
    func emptyBlockContainerIsNil() {
        let block = ComponentBlock(components: [])
        #expect(block.container == nil)
    }

    // MARK: - Identifiable

    @Test("Each ComponentBlock has a unique ID")
    func uniqueIDs() {
        let block1 = ComponentBlock(components: [])
        let block2 = ComponentBlock(components: [])
        #expect(block1.id != block2.id)
    }

    // MARK: - Hashable

    @Test("ComponentBlocks with same components produce different hashes due to unique IDs")
    func hashIncludesUniqueID() {
        let component = Component(text: "x", type: .text)
        let block1 = ComponentBlock(components: [component])
        let block2 = ComponentBlock(components: [component])
        #expect(block1 != block2)
    }

    // MARK: - Named Equation Types

    @Test("Named equation is an equation block")
    func namedEquationBlock() {
        let component = Component(text: "E=mc^2", type: .namedEquation)
        let block = ComponentBlock(components: [component])
        #expect(block.isEquationBlock == true)
    }

    @Test("Named no-number equation is an equation block")
    func namedNoNumberEquationBlock() {
        let component = Component(text: "E=mc^2", type: .namedNoNumberEquation)
        let block = ComponentBlock(components: [component])
        #expect(block.isEquationBlock == true)
    }

    @Test("TeX equation is an equation block")
    func texEquationBlock() {
        let component = Component(text: "E=mc^2", type: .texEquation)
        let block = ComponentBlock(components: [component])
        #expect(block.isEquationBlock == true)
    }
}
