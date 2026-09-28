import Foundation
import SwiftUI
import Testing

@testable import LaTeXSwiftUI

@Suite("Component Text Conversion Tests")
struct ComponentTextConversionTests {

  private static let validSVGString = """
    <svg style="vertical-align: -0.566ex;" width="2.127ex" height="2.262ex" viewBox="0 -750 940 1000" xmlns="http://www.w3.org/2000/svg"><path d=""/></svg>
    """

  private func makeSVG(errorText: String? = nil) throws -> SVG {
    try SVG(svgString: Self.validSVGString, errorText: errorText)
  }

  private func makeImageContainer() -> ImageContainer {
    ImageContainer(
      image: Image(systemName: "circle"), size: HashableCGSize(CGSize(width: 10, height: 10)))
  }

  // MARK: - Error branches

  @Test("Error SVG with original error mode uses original text")
  func errorOriginalMode() throws {
    let svg = try makeSVG(errorText: "bad input")
    let component = Component(text: "x^2", type: .inlineEquation, svg: svg)
    let text = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .original,
      blockRenderingMode: .blockViews,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
    #expect(text == Text(component.originalText))
  }

  @Test("Error SVG with original error mode and alwaysInline trims newlines")
  func errorOriginalModeAlwaysInline() throws {
    let svg = try makeSVG(errorText: "bad input")
    let component = Component(text: "\nx^2\n", type: .blockEquation, svg: svg)
    let text = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .original,
      blockRenderingMode: .alwaysInline,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
    #expect(text == Text(component.originalTextTrimmingNewlines))
  }

  @Test("Error SVG with error mode shows the error text")
  func errorErrorMode() throws {
    let svg = try makeSVG(errorText: "undefined control sequence")
    let component = Component(text: "x^2", type: .inlineEquation, svg: svg)
    let text = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .error,
      blockRenderingMode: .blockViews,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
    #expect(text == Text(verbatim: "undefined control sequence"))
  }

  @Test("Error SVG with rendered error mode falls through to the image path")
  func errorRenderedMode() throws {
    let svg = try makeSVG(errorText: "bad input")
    let component = Component(
      text: "x^2", type: .inlineEquation, svg: svg, imageContainer: makeImageContainer())
    _ = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .blockViews,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
  }

  @Test("Error SVG with renderedWithDiagnostic error mode falls through to the image path")
  func errorRenderedWithDiagnosticMode() throws {
    let svg = try makeSVG(errorText: "bad input")
    let component = Component(
      text: "x^2", type: .inlineEquation, svg: svg, imageContainer: makeImageContainer())
    _ = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .renderedWithDiagnostic,
      blockRenderingMode: .blockViews,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
  }

  // MARK: - Image branches

  @Test("SVG with image container produces a baseline-offset image text")
  func imageContainerPath() throws {
    let svg = try makeSVG()
    let component = Component(
      text: "x^2", type: .inlineEquation, svg: svg, imageContainer: makeImageContainer())
    _ = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .blockViews,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
  }

  @Test("SVG with image container inside equation block uses zero baseline offset")
  func imageContainerEquationBlockPath() throws {
    let svg = try makeSVG()
    let component = Component(
      text: "x^2", type: .blockEquation, svg: svg, imageContainer: makeImageContainer())
    _ = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .blockViews,
      isInEquationBlock: true,
      ignoreStringFormatting: false)
  }

  @Test("SVG without image container produces empty text")
  func missingImageContainerPath() throws {
    let svg = try makeSVG()
    let component = Component(text: "x^2", type: .inlineEquation, svg: svg)
    let text = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .blockViews,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
    #expect(text == Text(""))
  }

  // MARK: - Plain text branches

  @Test("Component without SVG in alwaysInline mode formats trimmed text")
  func noSVGAlwaysInline() {
    let component = Component(text: "\nhello\n", type: .text)
    _ = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .alwaysInline,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
  }

  @Test("Component without SVG in block mode formats original text")
  func noSVGBlockMode() {
    let component = Component(text: "hello", type: .text)
    _ = component.convertToText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .blockViews,
      isInEquationBlock: false,
      ignoreStringFormatting: false)
  }

  // MARK: - formattedText

  @Test("formattedText ignoring formatting returns plain text")
  func formattedTextIgnoringFormatting() {
    let component = Component(text: "**bold**", type: .text)
    let text = component.formattedText(input: "**bold**", ignoreStringFormatting: true)
    #expect(text == Text(verbatim: "**bold**"))
  }

  @Test("formattedText with formatting parses markdown")
  func formattedTextWithFormatting() {
    let component = Component(text: "**bold**", type: .text)
    let text = component.formattedText(input: "**bold**", ignoreStringFormatting: false)
    #expect(text != Text(verbatim: "**bold**"))
  }

  // MARK: - ComponentBlock.toText

  @Test("ComponentBlock toText concatenates component texts")
  @MainActor func componentBlockToText() {
    let block = ComponentBlock(components: [
      Component(text: "a", type: .text),
      Component(text: "b", type: .text),
    ])
    _ = block.toText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .blockViews,
      ignoreStringFormatting: true)
  }

  @Test("ComponentBlock toText for an equation block passes equation block context")
  @MainActor func componentBlockToTextEquationBlock() throws {
    let svg = try makeSVG()
    let block = ComponentBlock(components: [
      Component(
        text: "x^2", type: .blockEquation, svg: svg, imageContainer: makeImageContainer())
    ])
    #expect(block.isEquationBlock)
    _ = block.toText(
      xHeight: 10,
      displayScale: 2,
      renderingMode: .template,
      errorMode: .rendered,
      blockRenderingMode: .blockViews,
      ignoreStringFormatting: false)
  }

}
