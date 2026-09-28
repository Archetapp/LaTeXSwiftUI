import SwiftUI
import XCTest

@testable import LaTeXSwiftUI

final class EllSymbolTests: XCTestCase {
    func testParserPreservesEllInEveryEquationDelimiter() {
        let equation = #"52 = 2\ell + 2w, \ell = 8"#
        for type in Component.ComponentType.order {
            let source = "\(type.leftTerminator!)\(equation)\(type.rightTerminator!)"
            let components = Parser.parse(source)
            XCTAssertEqual(components.count, 1, source)
            XCTAssertEqual(components.first?.text, equation, source)
            XCTAssertEqual(components.first?.type, type, source)
            XCTAssertEqual(components.first?.originalText, source)
        }
    }

    func testEllSpeechNamesTheLetterWithoutChangingSource() {
        let source = #"52 = 2\ell + 2w, \ell = 8"#
        let component = Component(text: source, type: .inlineEquation)
        XCTAssertEqual(component.ellAccessibilityLabel, "52 = 2 letter ell + 2w, letter ell = 8")
        XCTAssertEqual(component.text, source)
        XCTAssertEqual(
            Component(text: "ℓ = 8", type: .blockEquation).ellAccessibilityLabel,
            "letter ell = 8"
        )
    }

    func testEllSpeechDoesNotReplaceOrdinaryLettersOrOtherCommands() {
        for source in ["52 = 2l + 2w", "l = 8", "1", #"\elliptic"#, #"\\ell"#] {
            XCTAssertNil(Component(text: source, type: .inlineEquation).ellAccessibilityLabel, source)
        }
        XCTAssertNil(Component(text: #"Write \ell in math mode"#, type: .text).ellAccessibilityLabel)
        XCTAssertEqual(
            Component(text: #"\ell_1^2 + l + 1 + \elliptic"#, type: .inlineEquation).ellAccessibilityLabel,
            #"letter ell _1^2 + l + 1 + \elliptic"#
        )
    }

    @MainActor
    func testRenderedEllTextRetainsItsBaselineAndSpeechLabel() throws {
        let component = try render(#"$\ell$"#)
        let svg = try XCTUnwrap(component.svg)
        let image = try XCTUnwrap(component.imageContainer).image
        let base = Text(image).baselineOffset(svg.geometry.verticalAlignment.toPoints(8))
        #if os(iOS) || os(visionOS)
        let expected = base
        #else
        let expected = Text("").font(.system(size: 0.1)) + base + Text("").font(.system(size: 0.1))
        #endif
        for mode in [LaTeX.BlockMode.alwaysInline, .blockViews] {
            let actual = component.convertToText(
                xHeight: 8, displayScale: 2, renderingMode: .template, errorMode: .original,
                blockRenderingMode: mode, isInEquationBlock: false, ignoreStringFormatting: false
            )
            XCTAssertEqual(actual, expected.accessibilityLabel(Text(verbatim: "letter ell")))
        }
    }

    @MainActor
    func testEllRendersInlineDisplayAndWithoutDelimiters() throws {
        for type in Component.ComponentType.order {
            let source = "\(type.leftTerminator!)52 = 2\\ell + 2w\(type.rightTerminator!)"
            let component = try render(source)
            XCTAssertEqual(component.type, type)
            XCTAssertEqual(component.ellAccessibilityLabel, "52 = 2 letter ell + 2w")
        }
        _ = try render(#"\ell = 8"#, parsingMode: .all)
        _ = try render(#"Length $\ell = 8$ gives width $w = 18$."#)
    }

    @MainActor
    func testEllUsesScriptGlyphAndNativeSpacingAndGeometry() throws {
        for type in [Component.ComponentType.inlineEquation, .texEquation] {
            let prefix = type.leftTerminator!
            let suffix = type.rightTerminator!
            let ell = try render(prefix + #"52 = 2\ell + 2w"# + suffix)
            let unicode = try render(prefix + #"52 = 2\mathit{ℓ} + 2w"# + suffix)
            XCTAssertEqual(ell.svg?.geometry, unicode.svg?.geometry)
            let svg = try XCTUnwrap(ell.svg)
            let xml = String(decoding: svg.data, as: UTF8.self)
            XCTAssertTrue(xml.contains("2113"), "Expected the U+2113 script ell glyph")
            XCTAssertTrue(xml.contains("<path"), "The glyph must use a font outline")
            XCTAssertFalse(xml.contains("<merror"))
            XCTAssertFalse(xml.contains("<text"), "The glyph must not depend on a fallback system font")
        }
        let ell = try render(#"$\ell$"#)
        let ordinaryL = try render("$l$")
        let one = try render("$1$")
        XCTAssertNotEqual(ell.svg?.data, ordinaryL.svg?.data)
        XCTAssertNotEqual(ell.svg?.data, one.svg?.data)
        XCTAssertEqual(ordinaryL.text, "l")
    }

    @MainActor
    func testEllSupportsSuperscriptsAndSubscripts() throws {
        let plain = try XCTUnwrap(render(#"$\ell$"#).svg)
        for (source, node) in [
            (#"\ell^2"#, "msup"), (#"\ell_1"#, "msub"),
            (#"\ell_{1}^{2}"#, "msubsup"), (#"\ell^{2}_{1}"#, "msubsup")
        ] {
            for delimiter in ["$", "$$"] {
                let svg = try XCTUnwrap(render(delimiter + source + delimiter).svg)
                let xml = String(decoding: svg.data, as: UTF8.self)
                XCTAssertTrue(xml.contains("2113"), source)
                XCTAssertTrue(xml.contains("data-mml-node=\"\(node)\""), source)
                XCTAssertGreaterThan(svg.geometry.height, plain.geometry.height, source)
                XCTAssertGreaterThan(svg.geometry.width, plain.geometry.width, source)
            }
        }
        _ = try render(#"$x^{\ell} + x_{\ell}$"#)
    }

    @MainActor
    private func render(_ source: String, parsingMode: LaTeX.ParsingMode = .onlyEquations) throws -> Component {
        let blocks = Renderer().renderSync(
            latex: source, unencodeHTML: false, parsingMode: parsingMode, processEscapes: false,
            errorMode: .original, xHeight: 8, displayScale: 2, renderingMode: .template
        )
        let component = try XCTUnwrap(blocks.flatMap(\.components).first { $0.type.isEquation }, source)
        let svg = try XCTUnwrap(component.svg, source)
        XCTAssertNil(svg.errorText, source)
        XCTAssertNotNil(component.imageContainer, source)
        XCTAssertGreaterThan(svg.geometry.width, 0, source)
        XCTAssertGreaterThan(svg.geometry.height, 0, source)
        XCTAssertTrue(svg.geometry.verticalAlignment.isFinite, source)
        return component
    }
}
