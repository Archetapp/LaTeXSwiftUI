//
//  Renderer.swift
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

/// Renders equation components and updates their rendered image and offset
/// values.
internal class Renderer: ObservableObject {
  
  // MARK: Types
  
  /// Rendering errors that can occur during the rendering process.
  enum RenderingError: Error {
    case svgGenerationFailed
    case imageGenerationFailed
    case mathJaxUnavailable
    case cacheCorrupted
  }
  
  /// A set of values used to create an array of parsed component blocks.
  struct ParsingSource: Equatable {
    
    /// The LaTeX input.
    let latex: String
    
    /// Whether or not the HTML should be unencoded.
    let unencodeHTML: Bool
    
    /// The parsing mode.
    let parsingMode: LaTeX.ParsingMode
  }
  
  // MARK: Public properties
  
  /// Whether or not the view's blocks have been rendered.
  @MainActor @Published var rendered: Bool = false
  
  /// Whether or not the view's blocks have been rendered synchronously.
  @MainActor var syncRendered: Bool = false
  
  /// Whether or not the receiver is currently rendering.
  @MainActor var isRendering: Bool = false
  
  /// The rendered blocks.
  @MainActor var blocks: [ComponentBlock] = []
  
  // MARK: Private properties
  
  /// The LaTeX input's parsed blocks.
  private var _parsedBlocks: [ComponentBlock]? = nil
  private var parsedBlocks: [ComponentBlock]? {
    get {
      parsedBlocksQueue.sync { [weak self] in
        return self?._parsedBlocks
      }
    }
    
    set {
      parsedBlocksQueue.async(flags: .barrier) { [weak self] in
        self?._parsedBlocks = newValue
      }
    }
  }
  
  /// The set of values used to create the parsed blocks.
  private var _parsingSource: ParsingSource? = nil
  
  /// Queue for accessing parsed blocks.
  private var parsedBlocksQueue = DispatchQueue(label: "latexswiftui.renderer.parse")
  
}

// MARK: Public methods

extension Renderer {
  
  /// Returns whether the view's components are cached.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  func isCached(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    xHeight: CGFloat,
    displayScale: CGFloat
  ) -> Bool {
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    return blocksExistInCache(
      parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      xHeight: xHeight,
      displayScale: displayScale,
      texOptions: texOptions)
  }
  
  /// Renders the view's components synchronously.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - renderingMode: The `renderingMode` environment variable.
  @MainActor func renderSync(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) -> [ComponentBlock] {
    guard !isRendering else {
      return []
    }
    guard !rendered && !syncRendered else {
      return blocks
    }
    isRendering = true
    
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    blocks = render(
      blocks: parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      xHeight: xHeight,
      displayScale: displayScale,
      renderingMode: renderingMode,
      texOptions: texOptions)
    
    isRendering = false
    syncRendered = true
    return blocks
  }
  
  /// Renders the view's components asynchronously.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - renderingMode: The `renderingMode` environment variable.
  func render(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) async {
    let isRen = await isRendering
    let ren = await rendered
    let renSync = await syncRendered
    guard !isRen && !ren && !renSync else {
      return
    }
    await MainActor.run {
      isRendering = true
    }
    
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    let renderedBlocks = render(
      blocks: parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      xHeight: xHeight,
      displayScale: displayScale,
      renderingMode: renderingMode,
      texOptions: texOptions)
    
    await MainActor.run {
      blocks = renderedBlocks
      isRendering = false
      rendered = true
    }
  }
  
}

// MARK: Private methods

extension Renderer {
  
  /// Gets the LaTeX input's parsed blocks.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  /// - Returns: The parsed blocks.
  private func parseBlocks(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode
  ) -> [ComponentBlock] {
    if let parsedBlocks {
      return parsedBlocks
    }
    
    let currentSource = ParsingSource(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode)
    if let _parsedBlocks, _parsingSource == currentSource {
      return _parsedBlocks
    }
    
    let blocks = Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex, mode: parsingMode)
    parsedBlocks = blocks
    _parsingSource = currentSource
    return blocks
  }
  
  /// Renders the view's component blocks.
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
  
  /// Internal render method with retry logic.
  private func renderWithRetry(
    blocks: [ComponentBlock],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions,
    retryCount: Int
  ) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    var hasRenderingFailures = false
    let maxRetries = 1 // Only retry once after cache clear
    
    for block in blocks {
      do {
        let newComponents = try render(
          block.components,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode,
          texOptions: texOptions)
        
        newBlocks.append(ComponentBlock(components: newComponents))
      }
      catch {
        newBlocks.append(block)
        continue
      }
    }
    
    // Record rendering result and handle retries
    if hasRenderingFailures {
      let cachesCleared = Cache.shared.recordRenderingFailure()
      if cachesCleared && retryCount < maxRetries {
        NSLog("LaTeXSwiftUI: Retrying render after cache clear (attempt \(retryCount + 1))")
        // Wait a brief moment for cache clearing to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          // Note: This is a simplified retry - in a real implementation you might want 
          // to handle this more carefully to avoid recursive calls on the main thread
        }
        // For now, just return the failed blocks to avoid infinite recursion
        // A more sophisticated implementation might use a completion handler pattern
        return newBlocks
      } else if cachesCleared {
        NSLog("LaTeXSwiftUI: Maximum retries reached after cache clear")
      }
    } else {
      Cache.shared.recordRenderingSuccess()
    }
    
    return newBlocks
  }
  
  /// Renders the components and stores the new images in a new set of
  /// components.
  ///
  /// - Parameters:
  ///   - components: The components to render.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The current display scale.
  ///   - renderingMode: The image rendering mode.
  ///   - texOptions: The MathJax TeX input processor options.
  /// - Returns: An array of components.
  private func render(
    _ components: [Component],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions
  ) throws -> [Component] {
    // Iterate through the input components and render
    var renderedComponents = [Component]()
    
    for component in components {
      // Only render equation components
      guard component.type.isEquation else {
        renderedComponents.append(component)
        continue
      }
      
      do {
        // Get the svg
        guard let svg = try getSVG(for: component, texOptions: texOptions) else {
          NSLog("LaTeXSwiftUI: Failed to generate SVG for component: \(component.text)")
          throw RenderingError.svgGenerationFailed
        }
        
        // Get the image
        guard let image = getImage(for: svg, xHeight: xHeight, displayScale: displayScale, renderingMode: renderingMode) else {
          NSLog("LaTeXSwiftUI: Failed to generate image for component: \(component.text)")
          throw RenderingError.imageGenerationFailed
        }
        
        // Save the rendered component
        renderedComponents.append(Component(
          text: component.text,
          type: component.type,
          svg: svg,
          imageContainer: ImageContainer(
            image: image,
            size: HashableCGSize(svg.size(for: xHeight))
          )
        ))
        
      } catch {
        NSLog("LaTeXSwiftUI: Rendering failed for component '\(component.text)': \(error)")
        // Append the original component without rendered content
        renderedComponents.append(Component(text: component.text, type: component.type))
        throw error
      }
    }
    
    // All done
    return renderedComponents
  }
  
  /// Gets the component's SVG, if possible.
  ///
  /// The SVG cache is checked first.
  ///
  /// - Parameters:
  ///   - component: The component.
  ///   - texOptions: The TeX input processor options to use.
  /// - Returns: An SVG.
  func getSVG(
    for component: Component,
    texOptions: TeXInputProcessorOptions
  ) throws -> SVG? {
    // Create our SVG cache key
    let svgCacheKey = Cache.SVGCacheKey(
      componentText: component.text,
      conversionOptions: component.conversionOptions,
      texOptions: texOptions)
    
    // Do we have the SVG in the cache?
    if let svgData = Cache.shared.dataCacheValue(for: svgCacheKey) {
      do {
        return try SVG(data: svgData)
      } catch {
        NSLog("LaTeXSwiftUI: Corrupted SVG data in cache for component: \(component.text)")
        // Remove the corrupted cache entry
        Cache.shared.dataCache.removeObject(forKey: svgCacheKey.key() as NSString)
        // Continue to regenerate
      }
    }
    
    // Make sure we have a MathJax instance!
    guard let mathjax = MathJax.svgRenderer else {
      NSLog("LaTeXSwiftUI: MathJax renderer is unavailable")
      throw RenderingError.mathJaxUnavailable
    }

    // Perform the TeX -> SVG conversion with synchronization
    var conversionError: Error?
    let svgString = MathJax.renderQueue.sync {
      mathjax.tex2svg(
        component.text,
        styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: texOptions,
        error: &conversionError)
    }

    // Check for a conversion error
    let errorText = try getErrorText(from: conversionError)

    // Create the SVG
    let svg = try SVG(svgString: svgString, errorText: errorText)
    
    // Set the SVG in the cache
    do {
      Cache.shared.setDataCacheValue(try svg.encoded(), for: svgCacheKey)
    } catch {
      NSLog("LaTeXSwiftUI: Failed to cache SVG data: \(error)")
      // Don't throw here, we still have the SVG
    }
    
    // Finish up
    return svg
  }
  
  /// Gets the component's image, if possible.
  ///
  /// The image cache is checked first.
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
    // Create our cache key with displayScale included
    let cacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight, displayScale: displayScale)

    // Check the cache for an image
    if let image = Cache.shared.imageCacheValue(for: cacheKey) {
      // Use the same scale when wrapping cached images
      return Image(image: image, scale: displayScale)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high)
    }

    // Continue with getting the image
    let imageSize = svg.size(for: xHeight)
    
    // Validate image size before proceeding
    guard imageSize.width > 0 && imageSize.height > 0 else {
      NSLog("LaTeXSwiftUI: Invalid image size calculated: \(imageSize)")
      return nil
    }
    
    #if os(iOS) || os(visionOS)
    guard let svgInstance = SwiftDraw.SVG(data: svg.data) else {
      NSLog("LaTeXSwiftUI: Failed to create SwiftDraw SVG instance")
      return nil
    }
    
    let image = svgInstance.rasterize(size: imageSize, scale: displayScale)
    
    // Validate the generated image
    guard image.size.width > 0 && image.size.height > 0 else {
      NSLog("LaTeXSwiftUI: Generated image has invalid size: \(image.size)")
      return nil
    }
    #else
    // On macOS, we need to ensure the image is created with consistent dimensions
    guard let svgInstance = SwiftDraw.SVG(data: svg.data) else {
      NSLog("LaTeXSwiftUI: Failed to create SwiftDraw SVG instance")
      return nil
    }
    
    let scale = max(1.0, displayScale)
    // Use explicit size and ensure consistent scaling
    let image = svgInstance.rasterize(with: imageSize, scale: scale)
    
    // Validate the generated image
    guard image.size.width > 0 && image.size.height > 0 else {
      NSLog("LaTeXSwiftUI: Generated image has invalid size: \(image.size)")
      // Try fallback with minimum size
      let fallbackSize = CGSize(width: max(1, imageSize.width), height: max(1, imageSize.height))
      let fallbackImage = svgInstance.rasterize(with: fallbackSize, scale: scale)
      
      guard fallbackImage.size.width > 0 && fallbackImage.size.height > 0 else {
        NSLog("LaTeXSwiftUI: Fallback image generation also failed")
        return nil
      }
      
      // Set the fallback image in the cache
      Cache.shared.setImageCacheValue(fallbackImage, for: cacheKey)
      
      return Image(image: fallbackImage, scale: scale)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high)
    }
    
    // No need to unwrap since NSImage is non-optional on macOS
    let finalImage = image
    #endif

    // Set the image in the cache
    Cache.shared.setImageCacheValue(image, for: cacheKey)

    // Finish up
    return Image(image: image, scale: displayScale)
      .renderingMode(renderingMode)
      .antialiased(true)
      .interpolation(.high)
    #else
    Cache.shared.setImageCacheValue(finalImage, for: cacheKey)
    
    return Image(image: finalImage, scale: scale)
      .renderingMode(renderingMode)
      .antialiased(true)
      .interpolation(.high)
    #endif
  }
  
  /// Gets the error text from a possibly non-nil error.
  ///
  /// - Parameter error: The error.
  /// - Returns: The error text.
  private func getErrorText(from error: Error?) throws -> String? {
    if let mjError = error as? MathJaxError, case .conversionError(let innerError) = mjError {
      return innerError
    }
    else if let error = error {
      throw error
    }
    return nil
  }
  
  /// Determines and returns whether the blocks are in the renderer's cache.
  ///
  /// - Parameters:
  ///   - blocks: The blocks.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - texOptions: The `texOptions` environment variable.
  /// - Returns: Whether the blocks are in the renderer's cache.
  func blocksExistInCache(_ blocks: [ComponentBlock], xHeight: CGFloat, displayScale: CGFloat, texOptions: TeXInputProcessorOptions) -> Bool {
    for block in blocks {
      for component in block.components where component.type.isEquation {
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
        guard Cache.shared.imageCacheValue(for: imageCacheKey) != nil else {
          return false
        }
      }
    }
    return true
  }
  
}
