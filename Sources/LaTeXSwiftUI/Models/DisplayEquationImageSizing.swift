//
//  DisplayEquationImageSizing.swift
//  LaTeXSwiftUI
//

import CoreGraphics

internal enum DisplayEquationImageSizing {
  struct Layout: Equatable {
    let scaleFactor: CGFloat
    let renderedSize: CGSize
    let visibleFrameWidth: CGFloat
    let requiresHorizontalScrolling: Bool
  }

  static let minimumScaleFactor: CGFloat = 0.65
  static let widthTolerance: CGFloat = 0.5

  static func layout(
    intrinsicSize: CGSize,
    availableWidth: CGFloat,
    minimumScaleFactor: CGFloat = minimumScaleFactor
  ) -> Layout {
    guard intrinsicSize.width.isFinite,
      intrinsicSize.height.isFinite,
      intrinsicSize.width > 0,
      intrinsicSize.height > 0
    else {
      return Layout(
        scaleFactor: 1,
        renderedSize: .zero,
        visibleFrameWidth: availableWidth.isFinite ? max(0, availableWidth) : 0,
        requiresHorizontalScrolling: false
      )
    }

    guard availableWidth.isFinite, availableWidth > 0 else {
      return Layout(
        scaleFactor: 1,
        renderedSize: intrinsicSize,
        visibleFrameWidth: intrinsicSize.width,
        requiresHorizontalScrolling: false
      )
    }

    let minimumScaleFactor = min(max(minimumScaleFactor, 0.01), 1)
    let scaleToFit = min(1, availableWidth / intrinsicSize.width)
    let scaleFactor = max(minimumScaleFactor, scaleToFit)
    let renderedSize = CGSize(
      width: intrinsicSize.width * scaleFactor,
      height: intrinsicSize.height * scaleFactor
    )
    let requiresHorizontalScrolling = renderedSize.width > availableWidth + widthTolerance

    return Layout(
      scaleFactor: scaleFactor,
      renderedSize: renderedSize,
      visibleFrameWidth: min(renderedSize.width, availableWidth),
      requiresHorizontalScrolling: requiresHorizontalScrolling
    )
  }
}
