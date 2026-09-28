//
//  LaTeX+Prewarm.swift
//  LaTeXSwiftUI
//

import MathJaxSwift
import SwiftUI

extension LaTeX {

  /// Renders the given LaTeX input and stores its SVG + image data in the
  /// shared cache without mounting a view.
  ///
  /// A later `LaTeX(latex)` configured with the same parsing/error options,
  /// `xHeight`, and `displayScale` finds its components already cached and
  /// paints synchronously on its first body evaluation, avoiding the brief
  /// loading-state frame that otherwise appears while a view transitions in.
  ///
  /// The expensive MathJax conversion runs on the renderer's background queue,
  /// so this is safe to call from any context. Awaiting it guarantees the
  /// shared cache is populated before continuing.
  ///
  /// The SVG layer of the cache is keyed only by the input text and conversion
  /// options, so it is reused across every `xHeight`/`displayScale`. The image
  /// layer is keyed by `xHeight` and `displayScale`, so those must match the
  /// values the eventual view resolves for the rendered image to be reused.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string (may contain `$...$` delimiters).
  ///   - unencodeHTML: Matches the view's `unencoded` modifier.
  ///   - parsingMode: Matches the view's `parsingMode` modifier.
  ///   - processEscapes: Matches the view's `processEscapes` modifier.
  ///   - errorMode: Matches the view's `errorMode` modifier.
  ///   - xHeight: The resolved x-height of the font the view renders with.
  ///   - displayScale: The display scale the view renders with.
  ///   - renderingMode: Matches the view's `imageRenderingMode` modifier.
  @MainActor
  public static func prewarm(
    _ latex: String,
    unencodeHTML: Bool = false,
    parsingMode: ParsingMode = .onlyEquations,
    processEscapes: Bool = false,
    errorMode: ErrorMode = .original,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode = .template
  ) async {
    let renderer = Renderer()
    await renderer.render(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: xHeight,
      displayScale: displayScale,
      renderingMode: renderingMode)
  }

  /// Convenience that prewarms the same input at several `xHeight` values,
  /// reusing the shared SVG so MathJax runs once per distinct input.
  ///
  /// Useful when the eventual view's font is not known precisely ahead of time
  /// but is one of a small known set (for example body and headline text).
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - xHeights: The candidate x-heights to rasterize for.
  ///   - displayScale: The display scale the view renders with.
  ///   - parsingMode: Matches the view's `parsingMode` modifier.
  ///   - errorMode: Matches the view's `errorMode` modifier.
  ///   - processEscapes: Matches the view's `processEscapes` modifier.
  ///   - renderingMode: Matches the view's `imageRenderingMode` modifier.
  @MainActor
  public static func prewarm(
    _ latex: String,
    xHeights: [CGFloat],
    displayScale: CGFloat,
    parsingMode: ParsingMode = .onlyEquations,
    errorMode: ErrorMode = .original,
    processEscapes: Bool = false,
    renderingMode: SwiftUI.Image.TemplateRenderingMode = .template
  ) async {
    for xHeight in xHeights {
      await prewarm(
        latex,
        parsingMode: parsingMode,
        processEscapes: processEscapes,
        errorMode: errorMode,
        xHeight: xHeight,
        displayScale: displayScale,
        renderingMode: renderingMode)
    }
  }
}
