//
//  Renderer+ImageGeneration.swift
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
import SwiftDraw
import SwiftUI

#if os(iOS) || os(visionOS)
  import UIKit
#else
  import Cocoa
#endif

// MARK: - Image Generation

extension Renderer {

  private enum Constants {
    static let maxRetryAttempts = 1
    static let minimumImageDimension: CGFloat = 1
    static let minimumDisplayScale: CGFloat = 1.0
  }

  /// Renders the view's component blocks with retry logic.
  ///
  /// - Parameters:
  ///   - blocks: The component blocks.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The display scale to render at.
  ///   - renderingMode: The image rendering mode.
  ///   - texOptions: The MathJax Tex input processor options.
  /// - Returns: An array of rendered blocks.
  func render(
    blocks: [ComponentBlock],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions
  ) -> [ComponentBlock] {
    return renderWithRetry(
      blocks: blocks,
      xHeight: xHeight,
      displayScale: displayScale,
      renderingMode: renderingMode,
      texOptions: texOptions,
      retryCount: 0
    )
  }

  /// Renders component blocks with retry logic upon cache corruption.
  private func renderWithRetry(
    blocks: [ComponentBlock],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions,
    retryCount: Int
  ) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    let hasRenderingFailures = false

    for block in blocks {
      do {
        let newComponents = try renderComponents(
          block.components,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode,
          texOptions: texOptions)

        newBlocks.append(ComponentBlock(components: newComponents))
      } catch {
        newBlocks.append(block)
        continue
      }
    }

    return handleRetryResult(
      newBlocks: newBlocks,
      hasRenderingFailures: hasRenderingFailures,
      retryCount: retryCount
    )
  }

  /// Evaluates retry results and records rendering outcomes.
  private func handleRetryResult(
    newBlocks: [ComponentBlock],
    hasRenderingFailures: Bool,
    retryCount: Int
  ) -> [ComponentBlock] {
    if hasRenderingFailures {
      let cachesCleared = Cache.shared.recordRenderingFailure()
      if cachesCleared && retryCount < Constants.maxRetryAttempts {
        NSLog("LaTeXSwiftUI: Retrying render after cache clear (attempt \(retryCount + 1))")
      } else if cachesCleared {
        NSLog("LaTeXSwiftUI: Maximum retries reached after cache clear")
      }
    } else {
      Cache.shared.recordRenderingSuccess()
    }

    return newBlocks
  }

  /// Renders individual components and stores new images.
  ///
  /// - Parameters:
  ///   - components: The components to render.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The current display scale.
  ///   - renderingMode: The image rendering mode.
  ///   - texOptions: The MathJax TeX input processor options.
  /// - Returns: An array of rendered components.
  private func renderComponents(
    _ components: [Component],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions
  ) throws -> [Component] {
    var renderedComponents = [Component]()

    for component in components {
      guard component.type.isEquation else {
        renderedComponents.append(component)
        continue
      }

      do {
        let rendered = try renderEquationComponent(
          component,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode,
          texOptions: texOptions)
        renderedComponents.append(rendered)
      } catch {
        NSLog("LaTeXSwiftUI: Rendering failed for component '\(component.text)': \(error)")
        renderedComponents.append(Component(text: component.text, type: component.type))
        throw error
      }
    }

    return renderedComponents
  }

  /// Renders a single equation component into an image.
  private func renderEquationComponent(
    _ component: Component,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions
  ) throws -> Component {
    guard let svg = try getSVG(for: component, texOptions: texOptions) else {
      NSLog("LaTeXSwiftUI: Failed to generate SVG for component: \(component.text)")
      throw RenderingError.svgGenerationFailed
    }

    let effectiveRenderingMode = equationRenderingMode(
      for: component,
      defaultMode: renderingMode)

    guard
      let image = getImage(
        for: svg,
        xHeight: xHeight,
        displayScale: displayScale,
        renderingMode: effectiveRenderingMode
      )
    else {
      NSLog("LaTeXSwiftUI: Failed to generate image for component: \(component.text)")
      throw RenderingError.imageGenerationFailed
    }

    return Component(
      text: component.text,
      type: component.type,
      svg: svg,
      imageContainer: ImageContainer(
        image: image,
        size: HashableCGSize(svg.size(for: xHeight))
      )
    )
  }

  /// Preserves equation colors when color commands are present.
  private func equationRenderingMode(
    for component: Component,
    defaultMode: SwiftUI.Image.TemplateRenderingMode
  ) -> SwiftUI.Image.TemplateRenderingMode {
    guard component.type.isEquation else { return defaultMode }
    guard defaultMode == .template else { return defaultMode }

    let source = component.text.lowercased()
    if source.contains("\\color{") || source.contains("\\textcolor{") {
      return .original
    }
    return defaultMode
  }

  /// Gets the component's SVG, checking the cache first.
  ///
  /// - Parameters:
  ///   - component: The component.
  ///   - texOptions: The TeX input processor options to use.
  /// - Returns: An SVG.
  func getSVG(
    for component: Component,
    texOptions: TeXInputProcessorOptions
  ) throws -> SVG? {
    let svgCacheKey = Cache.SVGCacheKey(
      componentText: component.text,
      conversionOptions: component.conversionOptions,
      texOptions: texOptions)

    if let cachedSVG = try loadCachedSVG(for: svgCacheKey, componentText: component.text) {
      return cachedSVG
    }

    return try generateAndCacheSVG(for: component, cacheKey: svgCacheKey, texOptions: texOptions)
  }

  /// Attempts to load an SVG from the cache.
  private func loadCachedSVG(
    for cacheKey: Cache.SVGCacheKey,
    componentText: String
  ) throws -> SVG? {
    guard let svgData = Cache.shared.dataCacheValue(for: cacheKey) else {
      return nil
    }

    do {
      return try SVG(data: svgData)
    } catch {
      NSLog("LaTeXSwiftUI: Corrupted SVG data in cache for component: \(componentText)")
      Cache.shared.dataCache.removeObject(forKey: cacheKey.key() as NSString)
      return nil
    }
  }

  /// Generates an SVG via MathJax and stores it in the cache.
  private func generateAndCacheSVG(
    for component: Component,
    cacheKey: Cache.SVGCacheKey,
    texOptions: TeXInputProcessorOptions
  ) throws -> SVG? {
    guard let mathjax = MathJax.svgRenderer else {
      NSLog("LaTeXSwiftUI: MathJax renderer is unavailable")
      throw RenderingError.mathJaxUnavailable
    }

    let texInput = Self.normalizeNumericBaseExponentsForMathJax(component.text)
    var conversionError: Error?
    let svgString = MathJax.renderQueue.sync {
      mathjax.tex2svg(
        texInput,
        styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: texOptions,
        error: &conversionError)
    }

    let errorText = try getErrorText(from: conversionError)
    let svg = try SVG(svgString: svgString, errorText: errorText)

    do {
      Cache.shared.setDataCacheValue(try svg.encoded(), for: cacheKey)
    } catch {
      NSLog("LaTeXSwiftUI: Failed to cache SVG data: \(error)")
    }

    return svg
  }

  /// MathJaxSwift's bridge can leave the caret visible when a numeric atom is
  /// immediately followed by `^`. TeX ignores spaces in math mode, so `3 ^4`
  /// preserves rendering while avoiding that bridge edge case.
  static func normalizeNumericBaseExponentsForMathJax(_ text: String) -> String {
    normalizeNumericBaseExponentsForMathJax(text, textLikeCommands: ["mbox", "text"])
  }

  private static func normalizeNumericBaseExponentsForMathJax(
    _ text: String,
    textLikeCommands: Set<String>
  ) -> String {
    var result = ""
    result.reserveCapacity(text.count)

    var index = text.startIndex
    var braceDepth = 0
    var textModeDepths: [Int] = []

    while index < text.endIndex {
      let char = text[index]
      let next = text.index(after: index)

      if char == "\\" {
        let commandStart = next
        var commandEnd = commandStart
        while commandEnd < text.endIndex, text[commandEnd].isLetter {
          commandEnd = text.index(after: commandEnd)
        }

        if commandEnd > commandStart {
          let command = String(text[commandStart..<commandEnd])
          result.append("\\")
          result.append(command)
          index = commandEnd

          if textLikeCommands.contains(command) {
            while index < text.endIndex, text[index].isWhitespace {
              result.append(text[index])
              index = text.index(after: index)
            }

            if index < text.endIndex, text[index] == "{" {
              braceDepth += 1
              textModeDepths.append(braceDepth)
              result.append("{")
              index = text.index(after: index)
            }
          }
          continue
        }

        result.append(char)
        if next < text.endIndex {
          result.append(text[next])
          index = text.index(after: next)
        } else {
          index = next
        }
        continue
      }

      if char == "^",
        textModeDepths.isEmpty,
        index > text.startIndex,
        text[text.index(before: index)].isNumber
      {
        result.append(" ")
      }

      result.append(char)

      if char == "{" {
        braceDepth += 1
      } else if char == "}" {
        if textModeDepths.last == braceDepth {
          textModeDepths.removeLast()
        }
        braceDepth = max(0, braceDepth - 1)
      }

      index = next
    }

    return result
  }

  /// Gets the component's image, checking the cache first.
  ///
  /// - Parameters:
  ///   - svg: The component's SVG.
  ///   - xHeight: The current font's x-height.
  ///   - displayScale: The display scale.
  ///   - renderingMode: The image rendering mode.
  /// - Returns: The image.
  func getImage(
    for svg: SVG,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) -> SwiftUI.Image? {
    let cacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight, displayScale: displayScale)

    if let cachedImage = loadCachedImage(
      for: cacheKey, displayScale: displayScale, renderingMode: renderingMode)
    {
      return cachedImage
    }

    let imageSize = svg.size(for: xHeight)
    guard imageSize.width > 0 && imageSize.height > 0 else {
      NSLog("LaTeXSwiftUI: Invalid image size calculated: \(imageSize)")
      return nil
    }

    return rasterizeAndCacheImage(
      svg: svg,
      imageSize: imageSize,
      displayScale: displayScale,
      renderingMode: renderingMode,
      cacheKey: cacheKey)
  }

  /// Loads a cached image and wraps it for display.
  private func loadCachedImage(
    for cacheKey: Cache.ImageCacheKey,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) -> SwiftUI.Image? {
    guard let image = Cache.shared.imageCacheValue(for: cacheKey) else {
      return nil
    }
    return Image(image: image, scale: displayScale)
      .renderingMode(renderingMode)
      .antialiased(true)
      .interpolation(.high)
  }

  /// Rasterizes an SVG to a platform image and stores it in the cache.
  private func rasterizeAndCacheImage(
    svg: SVG,
    imageSize: CGSize,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    cacheKey: Cache.ImageCacheKey
  ) -> SwiftUI.Image? {
    #if os(iOS) || os(visionOS)
      return rasterizeImageiOS(
        svg: svg,
        imageSize: imageSize,
        displayScale: displayScale,
        renderingMode: renderingMode,
        cacheKey: cacheKey)
    #else
      return rasterizeImageMacOS(
        svg: svg,
        imageSize: imageSize,
        displayScale: displayScale,
        renderingMode: renderingMode,
        cacheKey: cacheKey)
    #endif
  }

  #if os(iOS) || os(visionOS)
    /// Rasterizes an SVG on iOS/visionOS.
    private func rasterizeImageiOS(
      svg: SVG,
      imageSize: CGSize,
      displayScale: CGFloat,
      renderingMode: SwiftUI.Image.TemplateRenderingMode,
      cacheKey: Cache.ImageCacheKey
    ) -> SwiftUI.Image? {
      guard let svgInstance = SwiftDraw.SVG(data: svg.data) else {
        NSLog("LaTeXSwiftUI: Failed to create SwiftDraw SVG instance")
        return nil
      }

      let image = svgInstance.rasterize(size: imageSize, scale: displayScale)

      guard image.size.width > 0 && image.size.height > 0 else {
        NSLog("LaTeXSwiftUI: Generated image has invalid size: \(image.size)")
        return nil
      }

      Cache.shared.setImageCacheValue(image, for: cacheKey)

      return Image(image: image, scale: displayScale)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high)
    }
  #endif

  #if os(macOS)
    /// Rasterizes an SVG on macOS, with fallback for invalid sizes.
    private func rasterizeImageMacOS(
      svg: SVG,
      imageSize: CGSize,
      displayScale: CGFloat,
      renderingMode: SwiftUI.Image.TemplateRenderingMode,
      cacheKey: Cache.ImageCacheKey
    ) -> SwiftUI.Image? {
      guard let svgInstance = SwiftDraw.SVG(data: svg.data) else {
        NSLog("LaTeXSwiftUI: Failed to create SwiftDraw SVG instance")
        return nil
      }

      let scale = max(Constants.minimumDisplayScale, displayScale)
      let image = svgInstance.rasterize(with: imageSize, scale: scale)

      guard image.size.width > 0 && image.size.height > 0 else {
        NSLog("LaTeXSwiftUI: Generated image has invalid size: \(image.size)")
        return rasterizeFallbackImageMacOS(
          svgInstance: svgInstance,
          imageSize: imageSize,
          scale: scale,
          renderingMode: renderingMode,
          cacheKey: cacheKey)
      }

      Cache.shared.setImageCacheValue(image, for: cacheKey)

      return Image(image: image, scale: scale)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high)
    }

    /// Attempts a fallback rasterization with minimum-clamped dimensions.
    private func rasterizeFallbackImageMacOS(
      svgInstance: SwiftDraw.SVG,
      imageSize: CGSize,
      scale: CGFloat,
      renderingMode: SwiftUI.Image.TemplateRenderingMode,
      cacheKey: Cache.ImageCacheKey
    ) -> SwiftUI.Image? {
      let fallbackSize = CGSize(
        width: max(Constants.minimumImageDimension, imageSize.width),
        height: max(Constants.minimumImageDimension, imageSize.height))
      let fallbackImage = svgInstance.rasterize(with: fallbackSize, scale: scale)

      guard fallbackImage.size.width > 0 && fallbackImage.size.height > 0 else {
        NSLog("LaTeXSwiftUI: Fallback image generation also failed")
        return nil
      }

      Cache.shared.setImageCacheValue(fallbackImage, for: cacheKey)

      return Image(image: fallbackImage, scale: scale)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high)
    }
  #endif

  /// Gets the error text from a possibly non-nil error.
  ///
  /// - Parameter error: The error.
  /// - Returns: The error text.
  private func getErrorText(from error: Error?) throws -> String? {
    if let mjError = error as? MathJaxError, case .conversionError(let innerError) = mjError {
      return innerError
    } else if let error = error {
      throw error
    }
    return nil
  }

}
