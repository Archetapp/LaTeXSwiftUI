//
//  DisplayEquationImageSizingTests.swift
//  LaTeXSwiftUI
//

import XCTest
@testable import LaTeXSwiftUI

final class DisplayEquationImageSizingTests: XCTestCase {

  func testLayoutKeepsEquationWithinAvailableWidthWhenScaleCanFit() {
    let availableWidth: CGFloat = 360
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: 720, height: 120),
      availableWidth: availableWidth,
      minimumScaleFactor: 0.5
    )

    XCTAssertEqual(layout.scaleFactor, 0.5)
    XCTAssertEqual(layout.renderedSize, CGSize(width: 360, height: 60))
    XCTAssertLessThanOrEqual(layout.visibleFrameWidth, availableWidth)
    XCTAssertFalse(layout.requiresHorizontalScrolling)
  }

  func testLayoutFallsBackToScrollWidthAfterMinimumScale() {
    let availableWidth: CGFloat = 320
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: 1_000, height: 100),
      availableWidth: availableWidth,
      minimumScaleFactor: 0.65
    )

    XCTAssertEqual(layout.scaleFactor, 0.65)
    XCTAssertEqual(layout.renderedSize, CGSize(width: 650, height: 65))
    XCTAssertLessThanOrEqual(layout.visibleFrameWidth, availableWidth)
    XCTAssertTrue(layout.requiresHorizontalScrolling)
  }

  func testLayoutDoesNotUpscaleSmallEquations() {
    let layout = DisplayEquationImageSizing.layout(
      intrinsicSize: CGSize(width: 180, height: 40),
      availableWidth: 320
    )

    XCTAssertEqual(layout.scaleFactor, 1)
    XCTAssertEqual(layout.renderedSize, CGSize(width: 180, height: 40))
    XCTAssertEqual(layout.visibleFrameWidth, 180)
    XCTAssertFalse(layout.requiresHorizontalScrolling)
  }
}
