import CoreGraphics
import Foundation
import SwiftUI
import Testing

@testable import LaTeXSwiftUI

@Suite("DisplayEquationImageSizing Guard Tests")
struct DisplayEquationImageSizingGuardTests {

  @Test("Non-finite intrinsic width yields identity layout")
  func nonFiniteIntrinsicWidth() {
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: CGFloat.nan, height: 10),
      availableWidth: 100)
    #expect(layout.scaleFactor == CGFloat(1))
    #expect(layout.renderedSize == .zero)
    #expect(layout.visibleFrameWidth == CGFloat(100))
    #expect(!layout.requiresHorizontalScrolling)
  }

  @Test("Zero intrinsic size with infinite available width clamps frame to zero")
  func zeroIntrinsicSizeInfiniteWidth() {
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: .zero,
      availableWidth: .infinity)
    #expect(layout.scaleFactor == CGFloat(1))
    #expect(layout.renderedSize == .zero)
    #expect(layout.visibleFrameWidth == CGFloat(0))
  }

  @Test("Negative available width clamps visible frame to zero")
  func negativeAvailableWidthWithBadIntrinsic() {
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: -5, height: 10),
      availableWidth: -20)
    #expect(layout.visibleFrameWidth == CGFloat(0))
  }

  @Test("Non-finite available width uses the intrinsic size")
  func nonFiniteAvailableWidth() {
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: 40, height: 20),
      availableWidth: .infinity)
    #expect(layout.scaleFactor == CGFloat(1))
    #expect(layout.renderedSize == CGSize(width: 40, height: 20))
    #expect(layout.visibleFrameWidth == CGFloat(40))
    #expect(!layout.requiresHorizontalScrolling)
  }

  @Test("Zero available width uses the intrinsic size")
  func zeroAvailableWidth() {
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: 40, height: 20),
      availableWidth: 0)
    #expect(layout.renderedSize == CGSize(width: 40, height: 20))
  }

  @Test("Minimum scale factor is clamped into the unit range")
  func minimumScaleFactorClamping() {
    let tooBig = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: 200, height: 10),
      availableWidth: 100,
      minimumScaleFactor: 5)
    #expect(tooBig.scaleFactor == CGFloat(1))

    let tooSmall = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: 10000, height: 10),
      availableWidth: 10,
      minimumScaleFactor: -1)
    #expect(tooSmall.scaleFactor == CGFloat(0.01))
  }

}

@Suite("SVGGeometry Additional Tests")
struct SVGGeometryAdditionalTests {

  @Test("Missing svg element throws missingSVGElement")
  func missingSVGElement() {
    #expect(throws: SVGGeometry.ParsingError.self) {
      _ = try SVGGeometry(svg: "<div>no svg here</div>")
    }
  }

  @Test("Attributes with multiple equals signs are skipped")
  func attributeWithMultipleEquals() {
    let svg = """
      <svg data-info="a=b" style="vertical-align: -0.5ex;" width="2ex" height="1.5ex" viewBox="0 0 100 75"><path d=""/></svg>
      """
    let geometry = try? SVGGeometry(svg: svg)
    #expect(geometry != nil)
    #expect(geometry?.width == CGFloat(2))
  }

  @Test("toPoints converts x-heights using a platform font")
  func toPointsPlatformFont() {
    let font = _Font.preferredFont(forTextStyle: .body)
    let xHeight: SVGGeometry.XHeight = 2
    #expect(xHeight.toPoints(font) == 2 * font.xHeight)
  }

  @Test("toPoints converts x-heights using a SwiftUI font")
  func toPointsSwiftUIFont() {
    let xHeight: SVGGeometry.XHeight = 2
    let points = xHeight.toPoints(Font.body)
    #expect(points > 0)
  }

}

@Suite("Cache Key Fallback Tests")
struct CacheKeyFallbackTests {

  @Test("ImageCacheKey fallbackKey round-trips the SVG data")
  func imageCacheKeyFallback() throws {
    let svgString = """
      <svg style="vertical-align: -0.5ex;" width="2ex" height="1.5ex" viewBox="0 0 100 75"><path d=""/></svg>
      """
    let svg = try SVG(svgString: svgString)
    let key = Cache.ImageCacheKey(svg: svg, xHeight: 7, displayScale: 2)
    #expect(key.fallbackKey == svgString)
  }

}
