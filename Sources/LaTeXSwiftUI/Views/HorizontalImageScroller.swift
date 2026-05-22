//
//  HorizontalImageScroller.swift
//  LaTeXSwiftUI
//
//  Copyright (c) 2023 Colin Campbell
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import SwiftUI

/// A view that scales a display equation image before falling back to horizontal scrolling.
internal struct HorizontalImageScroller: View {
  
  /// The image to display.
  let image: Image
  
  /// The intrinsic size of the rendered image.
  let size: CGSize
  
  /// Whether the scroll view should show its indicators.
  var showsIndicators: Bool = true

  /// The smallest readable scale before horizontal scrolling takes over.
  var minimumScaleFactor: CGFloat = DisplayEquationImageSizing.minimumScaleFactor

  // MARK: View body
  
  var body: some View {
    if #available(iOS 16, macOS 13, *) {
      ViewThatFits(in: .horizontal) {
        fixedImage
        scaledImage(scaleFactor: 0.9)
        scaledImage(scaleFactor: 0.8)
        scaledImage(scaleFactor: 0.7)
        scaledImage(scaleFactor: minimumScaleFactor)
        ScrollView(.horizontal, showsIndicators: showsIndicators) {
          scaledImage(scaleFactor: minimumScaleFactor)
        }
      }
      .frame(maxWidth: .infinity, alignment: .center)
    } else {
      ScrollView(.horizontal, showsIndicators: showsIndicators) {
        scaledImage(scaleFactor: minimumScaleFactor)
      }
    }
  }

  private var fixedImage: some View {
    image
      .frame(width: size.width, height: size.height)
  }

  private func scaledImage(scaleFactor: CGFloat) -> some View {
    let scaleFactor = min(max(scaleFactor, 0.01), 1)
    return image
      .resizable()
      .aspectRatio(size, contentMode: .fit)
      .frame(
        width: size.width * scaleFactor,
        height: size.height * scaleFactor
      )
  }
}
