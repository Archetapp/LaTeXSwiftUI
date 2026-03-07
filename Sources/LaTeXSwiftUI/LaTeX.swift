//
//  LaTeX.swift
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

import HTMLEntities
import MathJaxSwift
import SwiftUI

/// A view that can parse and render TeX and LaTeX equations that contain
/// math-mode marcos.
public struct LaTeX: View {

  // MARK: Static properties

  /// The package's shared data cache.
  public static var dataCache: NSCache<NSString, NSData> {
    Cache.shared.dataCache
  }

#if os(macOS)
  /// The package's shared image cache.
  public static var imageCache: NSCache<NSString, NSImage> {
    Cache.shared.imageCache
  }
#else
  /// The package's shared image cache.
  public static var imageCache: NSCache<NSString, UIImage> {
    Cache.shared.imageCache
  }
#endif

  /// Releases the MathJax renderer instance to free memory (~512MB).
  ///
  /// Call this method when LaTeX rendering is no longer needed (e.g., when exiting a game)
  /// to reclaim the memory used by the JavaScriptCore context.
  /// The renderer will be lazily re-initialized on the next LaTeX render.
  ///
  /// - Note: This also clears the data and image caches.
  public static func releaseRenderer() {
    MathJax.releaseRenderer()
    dataCache.removeAllObjects()
    imageCache.removeAllObjects()
  }

  // MARK: Public properties

  /// The view's LaTeX input string.
  public let latex: String

  // MARK: Environment variables

  @Environment(\.errorMode) private var errorMode
  @Environment(\.unencodeHTML) private var unencodeHTML
  @Environment(\.parsingMode) private var parsingMode
  @Environment(\.blockMode) private var blockMode
  @Environment(\.processEscapes) private var processEscapes
  @Environment(\.renderingStyle) private var renderingStyle
  @Environment(\.imageRenderingMode) private var imageRenderingMode
  @Environment(\.renderingAnimation) private var renderingAnimation
  @Environment(\.ignoreStringFormatting) private var ignoreStringFormatting
  @Environment(\.displayScale) private var displayScale
  @Environment(\.font) private var font
  @Environment(\.platformFont) private var platformFont
  @Environment(\.fixedXHeight) private var fixedXHeight
  @Environment(\.fixedDisplayScale) private var fixedDisplayScale

  // MARK: Private properties

  @StateObject private var renderer = Renderer()
  @State private var preloadTask: Task<(), Never>?
  @State private var renderInvalidationKey: RenderInvalidationKey?

  // MARK: Initializers

  /// Initializes a view with a LaTeX input string.
  ///
  /// - Parameter latex: The LaTeX input.
  public init(_ latex: String) {
    self.latex = latex
  }

  // MARK: View body

  public var body: some View {
    VStack(spacing: 0) {
      if renderer.rendered || renderer.syncRendered {
        bodyWithBlocks(renderer.blocks)
      }
      else if isCached() {
        bodyWithBlocks(renderSync())
      }
      else {
        switch renderingStyle {
        case .empty, .original, .redactedOriginal, .progress:
          loadingView().task {
            await renderAsync()
          }
        case .wait:
          bodyWithBlocks(renderSync())
        }
      }
    }
    .animation(renderingAnimation, value: renderer.rendered)
    .onDisappear(perform: preloadTask?.cancel)
    .onAppear {
      invalidateRendererIfNeeded()
    }
    .onChange(of: currentRenderInvalidationKey) { _ in
      invalidateRendererIfNeeded()
    }
    #if os(macOS)
    .fixedSize(horizontal: false, vertical: true)
    .layoutPriority(1)
    #endif
  }

}

// MARK: - Public Methods

extension LaTeX {

  /// Preloads the view's SVG and image data.
  public func preload() {
    preloadTask?.cancel()
    preloadTask = Task { await renderAsync() }
    Task { await preloadTask?.value }
  }

  /// Configures the `LaTeX` view with the given style.
  ///
  /// - Parameter style: The `LaTeX` view style to use.
  /// - Returns: A stylized view.
  @available(*, deprecated, message: "This will be removed in a following version. Use other modifiers to set your style.")
  public func latexStyle<S>(_ style: S) -> some View where S: LaTeXStyle {
    style.makeBody(content: self)
  }

#if os(iOS) || os(visionOS)
  public func font(_ font: UIFont) -> some View {
    self
      .platformFont(font)
      .font(Font(font))
  }
#else
  public func font(_ font: NSFont) -> some View {
    self
      .platformFont(font)
      .font(Font(font))
  }
#endif
}

// MARK: - Private Methods

extension LaTeX {

  var resolvedXHeight: CGFloat {
    fixedXHeight ?? (platformFont?.xHeight ?? font?.xHeight) ?? Font.body.xHeight
  }

  var resolvedDisplayScale: CGFloat {
    fixedDisplayScale ?? displayScale
  }

  var currentRenderInvalidationKey: RenderInvalidationKey {
    RenderInvalidationKey(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: resolvedXHeight,
      displayScale: resolvedDisplayScale)
  }

  @MainActor private func invalidateRendererIfNeeded() {
    let key = currentRenderInvalidationKey
    guard renderInvalidationKey != key else { return }
    renderInvalidationKey = key
    renderer.invalidateRenderState()
  }

  /// Checks the renderer's caches for the current view.
  private func isCached() -> Bool {
    return renderer.isCached(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: resolvedXHeight,
      displayScale: resolvedDisplayScale)
  }

  /// Renders the view's components asynchronously.
  private func renderAsync() async {
    await renderer.render(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: resolvedXHeight,
      displayScale: resolvedDisplayScale,
      renderingMode: imageRenderingMode)
  }

  /// Renders the view's components synchronously.
  ///
  /// - Returns: The rendered components.
  private func renderSync() -> [ComponentBlock] {
    return renderer.renderSync(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: resolvedXHeight,
      displayScale: resolvedDisplayScale,
      renderingMode: imageRenderingMode)
  }

  /// Creates the view's body based on its block mode.
  ///
  /// - Parameter blocks: The blocks to display.
  /// - Returns: The view's body.
  @MainActor @ViewBuilder private func bodyWithBlocks(_ blocks: [ComponentBlock]) -> some View {
    switch blockMode {
    case .alwaysInline:
      ComponentBlocksText(blocks: blocks, forceInline: true)
    case .blockText:
      ComponentBlocksText(blocks: blocks)
    case .blockViews:
      ComponentBlocksViews(blocks: blocks)
    }
  }

  /// The view to display while its content is rendering.
  ///
  /// - Returns: The view's body.
  @MainActor @ViewBuilder private func loadingView() -> some View {
    switch renderingStyle {
    case .empty:
      Text("")
    case .original:
      Text(latex)
    case .redactedOriginal:
      Text(latex).redacted(reason: .placeholder)
    case .progress:
      ProgressView()
    default:
      EmptyView()
    }
  }

}
