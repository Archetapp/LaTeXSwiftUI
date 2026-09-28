import Foundation
import SwiftUI
import Testing

@testable import LaTeXSwiftUI

@Suite("LaTeX View Modifier Tests")
struct LaTeXViewModifierTests {

  @Test("Environment-writing modifiers produce views")
  func environmentModifiers() {
    let base = Text("x")
    _ = base.imageRenderingMode(.original)
    _ = base.errorMode(.error)
    _ = base.unencoded()
    _ = base.unencoded(false)
    _ = base.parsingMode(.all)
    _ = base.blockMode(.blockText)
    _ = base.processEscapes()
    _ = base.processEscapes(false)
    _ = base.equationNumberMode(.left)
    _ = base.equationNumberStart(2)
    _ = base.equationNumberOffset(4)
    _ = base.formatEquationNumber { "eq. \($0)" }
    _ = base.renderingStyle(.progress)
    _ = base.renderingAnimation(.easeOut)
    _ = base.ignoreStringFormatting()
    _ = base.ignoreStringFormatting(false)
    _ = base.blockAlignment(.center)
    _ = base.fixedXHeight(7)
    _ = base.fixedDisplayScale(2)
  }

  @Test("latexStandardConfiguration applies the standard modifier stack")
  func latexStandardConfigurationModifier() {
    _ = Text("x").latexStandardConfiguration(fixedXHeightValue: 7)
    _ = Text("x").latexStandardConfiguration(
      fixedXHeightValue: 7, fixedDisplayScale: 3, blockAlignment: .trailing)
  }

  @Test("preload on a non-LaTeX view is a no-op")
  func preloadNonLaTeXView() {
    _ = Text("x").preload()
  }

  @Test("standardConfiguration with a SwiftUI font produces a view")
  func standardConfigurationSwiftUIFont() {
    let latex = LaTeX("$x^2$")
    _ = latex.standardConfiguration(font: .body, fixedXHeightValue: 7)
    _ = latex.standardConfiguration(
      font: .headline, fixedXHeightValue: 7, fixedDisplayScale: 3,
      latexBlockAlignment: .leading)
  }

  #if os(iOS) || os(visionOS)
    @Test("standardConfiguration with a UIFont produces a view")
    func standardConfigurationPlatformFont() {
      let latex = LaTeX("$x^2$")
      _ = latex.standardConfiguration(
        font: UIFont.systemFont(ofSize: 14), fixedXHeightValue: 7)
    }
  #else
    @Test("standardConfiguration with an NSFont produces a view")
    func standardConfigurationPlatformFont() {
      let latex = LaTeX("$x^2$")
      _ = latex.standardConfiguration(
        font: NSFont.systemFont(ofSize: 14), fixedXHeightValue: 7)
    }
  #endif

  @Test("platform font modifier produces a view")
  func platformFontModifier() {
    let latex = LaTeX("$x^2$")
    #if os(iOS) || os(visionOS)
      _ = latex.font(UIFont.systemFont(ofSize: 12))
    #else
      _ = latex.font(NSFont.systemFont(ofSize: 12))
    #endif
  }

  @Test("Default LaTeX style returns the content unchanged")
  func defaultLaTeXStyle() {
    let style: DefaultLaTeXStyle = .automatic
    _ = style.makeBody(content: LaTeX("$x$"))
  }

  @Test("Standard LaTeX style wraps the content with modifiers")
  func standardLaTeXStyle() {
    let style: StandardLaTeXStyle = .standard
    _ = style.makeBody(content: LaTeX("$x$"))
  }

}
