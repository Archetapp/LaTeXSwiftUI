import Foundation
import SwiftUI
import Testing

@testable import LaTeXSwiftUI

@Suite("EnvironmentValues LaTeX Tests")
struct EnvironmentValuesLaTeXTests {

  @Test("imageRenderingMode defaults to template and is settable")
  func imageRenderingMode() {
    var env = EnvironmentValues()
    #expect(env.imageRenderingMode == .template)
    env.imageRenderingMode = .original
    #expect(env.imageRenderingMode == .original)
  }

  @Test("errorMode defaults to original and is settable")
  func errorMode() {
    var env = EnvironmentValues()
    #expect(env.errorMode == .original)
    env.errorMode = .error
    #expect(env.errorMode == .error)
  }

  @Test("unencodeHTML defaults to false and is settable")
  func unencodeHTML() {
    var env = EnvironmentValues()
    #expect(env.unencodeHTML == false)
    env.unencodeHTML = true
    #expect(env.unencodeHTML == true)
  }

  @Test("parsingMode defaults to onlyEquations and is settable")
  func parsingMode() {
    var env = EnvironmentValues()
    #expect(env.parsingMode == .onlyEquations)
    env.parsingMode = .all
    #expect(env.parsingMode == .all)
  }

  @Test("blockMode defaults to blockViews and is settable")
  func blockMode() {
    var env = EnvironmentValues()
    #expect(env.blockMode == .blockViews)
    env.blockMode = .alwaysInline
    #expect(env.blockMode == .alwaysInline)
  }

  @Test("processEscapes defaults to false and is settable")
  func processEscapes() {
    var env = EnvironmentValues()
    #expect(env.processEscapes == false)
    env.processEscapes = true
    #expect(env.processEscapes == true)
  }

  @Test("equationNumberMode defaults to none and is settable")
  func equationNumberMode() {
    var env = EnvironmentValues()
    #expect(env.equationNumberMode == .none)
    env.equationNumberMode = .right
    #expect(env.equationNumberMode == .right)
  }

  @Test("equationNumberStart defaults to 1 and is settable")
  func equationNumberStart() {
    var env = EnvironmentValues()
    #expect(env.equationNumberStart == 1)
    env.equationNumberStart = 5
    #expect(env.equationNumberStart == 5)
  }

  @Test("equationNumberOffset defaults to 0 and is settable")
  func equationNumberOffset() {
    var env = EnvironmentValues()
    #expect(env.equationNumberOffset == CGFloat(0))
    env.equationNumberOffset = 12
    #expect(env.equationNumberOffset == CGFloat(12))
  }

  @Test("formatEquationNumber default wraps the number in parentheses")
  func formatEquationNumber() {
    var env = EnvironmentValues()
    #expect(env.formatEquationNumber(3) == "(3)")
    env.formatEquationNumber = { "[\($0)]" }
    #expect(env.formatEquationNumber(3) == "[3]")
  }

  @Test("renderingStyle defaults to original and is settable")
  func renderingStyle() {
    var env = EnvironmentValues()
    #expect(env.renderingStyle == .original)
    env.renderingStyle = .progress
    #expect(env.renderingStyle == .progress)
  }

  @Test("renderingAnimation defaults to none and is settable")
  func renderingAnimation() {
    var env = EnvironmentValues()
    #expect(env.renderingAnimation == Animation?.none)
    env.renderingAnimation = .easeIn
    #expect(env.renderingAnimation == .easeIn)
  }

  @Test("ignoreStringFormatting defaults to false and is settable")
  func ignoreStringFormatting() {
    var env = EnvironmentValues()
    #expect(env.ignoreStringFormatting == false)
    env.ignoreStringFormatting = true
    #expect(env.ignoreStringFormatting == true)
  }

  @Test("platformFont defaults to nil and is settable")
  func platformFont() {
    var env = EnvironmentValues()
    #expect(env.platformFont == nil)
    let font = _Font.systemFont(ofSize: 14)
    env.platformFont = font
    #expect(env.platformFont == font)
  }

  @Test("blockAlignment defaults to leading and is settable")
  func blockAlignment() {
    var env = EnvironmentValues()
    #expect(env.blockAlignment == .leading)
    env.blockAlignment = .trailing
    #expect(env.blockAlignment == .trailing)
  }

  @Test("fixedXHeight defaults to nil and is settable")
  func fixedXHeight() {
    var env = EnvironmentValues()
    #expect(env.fixedXHeight == nil)
    env.fixedXHeight = 8
    #expect(env.fixedXHeight == CGFloat(8))
  }

  @Test("fixedDisplayScale defaults to nil and is settable")
  func fixedDisplayScale() {
    var env = EnvironmentValues()
    #expect(env.fixedDisplayScale == nil)
    env.fixedDisplayScale = 3
    #expect(env.fixedDisplayScale == CGFloat(3))
  }

}
