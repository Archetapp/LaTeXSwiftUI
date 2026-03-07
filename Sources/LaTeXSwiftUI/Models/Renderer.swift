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
import SwiftUI

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

// MARK: - Public Methods

extension Renderer {

  /// Resets all render state so the view can be re-rendered.
  @MainActor func invalidateRenderState() {
    rendered = false
    syncRendered = false
    isRendering = false
    blocks = []

    parsedBlocksQueue.sync(flags: .barrier) {
      _parsedBlocks = nil
      _parsingSource = nil
    }
  }

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

// MARK: - Parsing

extension Renderer {

  /// Gets the LaTeX input's parsed blocks, using a cached result
  /// when the parsing source has not changed.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  /// - Returns: The parsed blocks.
  func parseBlocks(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode
  ) -> [ComponentBlock] {
    let currentSource = ParsingSource(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode)
    if let parsedBlocks, _parsingSource == currentSource {
      return parsedBlocks
    }

    let blocks = Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex, mode: parsingMode)
    parsedBlocks = blocks
    _parsingSource = currentSource
    return blocks
  }

}
