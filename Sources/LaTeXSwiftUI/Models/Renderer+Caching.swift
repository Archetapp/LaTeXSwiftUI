//
//  Renderer+Caching.swift
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

import Foundation
import MathJaxSwift

// MARK: - Caching

extension Renderer {

  /// Determines whether all equation components in the given blocks
  /// have both SVG data and rendered images present in the cache.
  ///
  /// - Parameters:
  ///   - blocks: The blocks to check.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - texOptions: The TeX input processor options.
  /// - Returns: Whether the blocks are fully cached.
  func blocksExistInCache(
    _ blocks: [ComponentBlock],
    xHeight: CGFloat,
    displayScale: CGFloat,
    texOptions: TeXInputProcessorOptions
  ) -> Bool {
    for block in blocks {
      for component in block.components where component.type.isEquation {
        guard isComponentCached(component, xHeight: xHeight, displayScale: displayScale, texOptions: texOptions) else {
          return false
        }
      }
    }
    return true
  }

  /// Checks whether a single equation component has both its SVG
  /// data and rendered image in the cache.
  private func isComponentCached(
    _ component: Component,
    xHeight: CGFloat,
    displayScale: CGFloat,
    texOptions: TeXInputProcessorOptions
  ) -> Bool {
    let dataCacheKey = Cache.SVGCacheKey(
      componentText: component.text,
      conversionOptions: component.conversionOptions,
      texOptions: texOptions)

    guard let svgData = Cache.shared.dataCacheValue(for: dataCacheKey) else {
      return false
    }

    guard let svg = try? SVG(data: svgData) else {
      return false
    }

    let imageCacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight, displayScale: displayScale)
    return Cache.shared.imageCacheValue(for: imageCacheKey) != nil
  }

}
