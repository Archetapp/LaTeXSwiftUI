import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("Component Model Tests")
struct ComponentTests {

    // MARK: - ComponentType Properties

    @Test("ComponentType description matches rawValue")
    func componentTypeDescription() {
        let types: [Component.ComponentType] = [
            .text, .inlineEquation, .inlineParenthesesEquation,
            .texEquation, .blockEquation, .namedEquation, .namedNoNumberEquation
        ]
        for type in types {
            #expect(type.description == type.rawValue)
        }
    }

    @Test("ComponentType leftTerminator values are correct")
    func componentTypeLeftTerminators() {
        #expect(Component.ComponentType.text.leftTerminator == nil)
        #expect(Component.ComponentType.inlineEquation.leftTerminator == "$")
        #expect(Component.ComponentType.inlineParenthesesEquation.leftTerminator == "\\(")
        #expect(Component.ComponentType.texEquation.leftTerminator == "$$")
        #expect(Component.ComponentType.blockEquation.leftTerminator == "\\[")
        #expect(Component.ComponentType.namedEquation.leftTerminator == "\\begin{equation}")
        #expect(Component.ComponentType.namedNoNumberEquation.leftTerminator == "\\begin{equation*}")
    }

    @Test("ComponentType rightTerminator values are correct")
    func componentTypeRightTerminators() {
        #expect(Component.ComponentType.text.rightTerminator == nil)
        #expect(Component.ComponentType.inlineEquation.rightTerminator == "$")
        #expect(Component.ComponentType.inlineParenthesesEquation.rightTerminator == "\\)")
        #expect(Component.ComponentType.texEquation.rightTerminator == "$$")
        #expect(Component.ComponentType.blockEquation.rightTerminator == "\\]")
        #expect(Component.ComponentType.namedEquation.rightTerminator == "\\end{equation}")
        #expect(Component.ComponentType.namedNoNumberEquation.rightTerminator == "\\end{equation*}")
    }

    @Test("ComponentType inline property returns true for inline types only")
    func componentTypeInlineProperty() {
        #expect(Component.ComponentType.text.inline == true)
        #expect(Component.ComponentType.inlineEquation.inline == true)
        #expect(Component.ComponentType.inlineParenthesesEquation.inline == true)
        #expect(Component.ComponentType.texEquation.inline == false)
        #expect(Component.ComponentType.blockEquation.inline == false)
        #expect(Component.ComponentType.namedEquation.inline == false)
        #expect(Component.ComponentType.namedNoNumberEquation.inline == false)
    }

    @Test("ComponentType isEquation returns false only for text")
    func componentTypeIsEquation() {
        #expect(Component.ComponentType.text.isEquation == false)
        #expect(Component.ComponentType.inlineEquation.isEquation == true)
        #expect(Component.ComponentType.inlineParenthesesEquation.isEquation == true)
        #expect(Component.ComponentType.texEquation.isEquation == true)
        #expect(Component.ComponentType.blockEquation.isEquation == true)
        #expect(Component.ComponentType.namedEquation.isEquation == true)
        #expect(Component.ComponentType.namedNoNumberEquation.isEquation == true)
    }

    @Test("ComponentType order contains all equation types in scan priority")
    func componentTypeOrder() {
        let order = Component.ComponentType.order
        #expect(order.count == 6)
        #expect(order[0] == .namedNoNumberEquation)
        #expect(order[1] == .namedEquation)
        #expect(order[2] == .blockEquation)
        #expect(order[3] == .texEquation)
        #expect(order[4] == .inlineEquation)
        #expect(order[5] == .inlineParenthesesEquation)
    }

    // MARK: - Component Initialization

    @Test("Text component preserves text without stripping")
    func textComponentInitialization() {
        let component = Component(text: "Hello, World!", type: .text)
        #expect(component.text == "Hello, World!")
        #expect(component.type == .text)
        #expect(component.svg == nil)
        #expect(component.imageContainer == nil)
    }

    @Test("Inline equation strips dollar sign terminators")
    func inlineEquationStripsTerminators() {
        let component = Component(text: "$x^2$", type: .inlineEquation)
        #expect(component.text == "x^2")
    }

    @Test("TeX equation strips double dollar sign terminators")
    func texEquationStripsTerminators() {
        let component = Component(text: "$$x^2$$", type: .texEquation)
        #expect(component.text == "x^2")
    }

    @Test("Block equation strips bracket terminators")
    func blockEquationStripsTerminators() {
        let component = Component(text: "\\[x^2\\]", type: .blockEquation)
        #expect(component.text == "x^2")
    }

    @Test("Named equation strips begin/end terminators")
    func namedEquationStripsTerminators() {
        let component = Component(text: "\\begin{equation}x^2\\end{equation}", type: .namedEquation)
        #expect(component.text == "x^2")
    }

    @Test("Named no-number equation strips begin/end star terminators")
    func namedNoNumberEquationStripsTerminators() {
        let component = Component(text: "\\begin{equation*}x^2\\end{equation*}", type: .namedNoNumberEquation)
        #expect(component.text == "x^2")
    }

    @Test("Parentheses equation strips backslash-paren terminators")
    func parenthesesEquationStripsTerminators() {
        let component = Component(text: "\\(x^2\\)", type: .inlineParenthesesEquation)
        #expect(component.text == "x^2")
    }

    @Test("Equation component without terminators in text preserves text")
    func equationWithoutTerminators() {
        let component = Component(text: "x^2", type: .inlineEquation)
        #expect(component.text == "x^2")
    }

    // MARK: - Component Properties

    @Test("originalText reconstructs input with terminators for equations")
    func originalTextReconstruction() {
        let component = Component(text: "x^2", type: .inlineEquation)
        #expect(component.originalText == "$x^2$")
    }

    @Test("originalText for text type has no terminators")
    func originalTextForPlainText() {
        let component = Component(text: "Hello", type: .text)
        #expect(component.originalText == "Hello")
    }

    @Test("originalText reconstructs all equation types correctly")
    func originalTextForAllEquationTypes() {
        let inlineComponent = Component(text: "x", type: .inlineEquation)
        #expect(inlineComponent.originalText == "$x$")

        let parenComponent = Component(text: "x", type: .inlineParenthesesEquation)
        #expect(parenComponent.originalText == "\\(x\\)")

        let texComponent = Component(text: "x", type: .texEquation)
        #expect(texComponent.originalText == "$$x$$")

        let blockComponent = Component(text: "x", type: .blockEquation)
        #expect(blockComponent.originalText == "\\[x\\]")

        let namedComponent = Component(text: "x", type: .namedEquation)
        #expect(namedComponent.originalText == "\\begin{equation}x\\end{equation}")

        let namedStarComponent = Component(text: "x", type: .namedNoNumberEquation)
        #expect(namedStarComponent.originalText == "\\begin{equation*}x\\end{equation*}")
    }

    @Test("originalTextTrimmingNewlines strips leading and trailing newlines")
    func originalTextTrimmingNewlines() {
        let component = Component(text: "\nx^2\n", type: .inlineEquation)
        #expect(component.originalTextTrimmingNewlines == "$\nx^2\n$")
        let trimmed = component.originalTextTrimmingNewlines
        #expect(!trimmed.hasPrefix("\n"))
        #expect(!trimmed.hasSuffix("\n"))
    }

    @Test("conversionOptions display property matches inline status")
    func conversionOptionsDisplay() {
        let inlineComponent = Component(text: "x", type: .inlineEquation)
        #expect(inlineComponent.conversionOptions.display == false)

        let blockComponent = Component(text: "x", type: .blockEquation)
        #expect(blockComponent.conversionOptions.display == true)

        let textComponent = Component(text: "x", type: .text)
        #expect(textComponent.conversionOptions.display == false)
    }

    @Test("description format includes type and text")
    func componentDescription() {
        let component = Component(text: "x^2", type: .inlineEquation)
        #expect(component.description == "(inlineEquation, \"x^2\")")
    }

    // MARK: - Component Equality

    @Test("Components with same text and type are equal")
    func componentEquality() {
        let a = Component(text: "x^2", type: .inlineEquation)
        let b = Component(text: "x^2", type: .inlineEquation)
        #expect(a == b)
    }

    @Test("Components with different text are not equal")
    func componentInequalityByText() {
        let a = Component(text: "x^2", type: .inlineEquation)
        let b = Component(text: "y^2", type: .inlineEquation)
        #expect(a != b)
    }

    @Test("Components with different types are not equal")
    func componentInequalityByType() {
        let a = Component(text: "x^2", type: .inlineEquation)
        let b = Component(text: "x^2", type: .blockEquation)
        #expect(a != b)
    }

    // MARK: - Component Hashing

    @Test("Equal components produce the same hash")
    func componentHashConsistency() {
        let a = Component(text: "x^2", type: .inlineEquation)
        let b = Component(text: "x^2", type: .inlineEquation)
        #expect(a.hashValue == b.hashValue)
    }
}
