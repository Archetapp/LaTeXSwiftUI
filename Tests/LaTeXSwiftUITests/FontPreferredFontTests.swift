import Foundation
import SwiftUI
import Testing

@testable import LaTeXSwiftUI

@Suite("Font Extension Tests")
struct FontPreferredFontTests {

  private static let baseFonts: [(Font, _Font.TextStyle)] = [
    (.largeTitle, .largeTitle),
    (.title, .title1),
    (.title2, .title2),
    (.title3, .title3),
    (.headline, .headline),
    (.subheadline, .subheadline),
    (.callout, .callout),
    (.caption, .caption1),
    (.caption2, .caption2),
    (.footnote, .footnote),
  ]

  @Test("textStyle maps base fonts to platform text styles")
  func textStyleBaseFonts() {
    for (font, expected) in Self.baseFonts {
      #expect(font.textStyle() == expected)
    }
  }

  @Test("textStyle maps styled variants to the same text style")
  func textStyleStyledVariants() {
    #expect(Font.largeTitle.bold().textStyle() == .largeTitle)
    #expect(Font.title.italic().textStyle() == .title1)
    #expect(Font.headline.monospaced().textStyle() == .headline)
    #expect(Font.footnote.bold().textStyle() == .footnote)
  }

  @Test("textStyle returns nil for custom fonts")
  func textStyleCustomFont() {
    #expect(Font.system(size: 13.5).textStyle() == nil)
  }

  @Test("xHeight is positive for standard fonts")
  func xHeightPositive() {
    #expect(Font.body.xHeight > 0)
    #expect(Font.largeTitle.xHeight > 0)
    #expect(Font.caption.xHeight <= Font.largeTitle.xHeight)
  }

  @Test("preferredFont falls back to body for unknown fonts")
  func preferredFontFallback() {
    let font = _Font.preferredFont(from: .system(size: 99))
    #expect(font == _Font.preferredFont(forTextStyle: .body))
  }

  @Test("preferredFont resolves plain fonts")
  func preferredFontPlain() {
    for (font, style) in Self.baseFonts {
      let resolved = _Font.preferredFont(from: font)
      #expect(resolved == _Font.preferredFont(forTextStyle: style))
    }
  }

  @Test("preferredFont resolves bold variants")
  func preferredFontBold() {
    for (font, _) in Self.baseFonts {
      let resolved = _Font.preferredFont(from: font.bold())
      #expect(resolved.pointSize > 0)
    }
  }

  @Test("preferredFont resolves italic variants")
  func preferredFontItalic() {
    for (font, _) in Self.baseFonts {
      let resolved = _Font.preferredFont(from: font.italic())
      #expect(resolved.pointSize > 0)
    }
  }

  @Test("preferredFont resolves monospaced variants")
  func preferredFontMonospaced() {
    for (font, _) in Self.baseFonts {
      let resolved = _Font.preferredFont(from: font.monospaced())
      #expect(resolved.pointSize > 0)
    }
  }

}
