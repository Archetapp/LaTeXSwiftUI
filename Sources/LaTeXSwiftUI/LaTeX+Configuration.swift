//
//  LaTeX+Configuration.swift
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

// MARK: - Public Types

extension LaTeX {

  /// A closure that takes an equation number and returns a string to display in
  /// the view.
  public typealias FormatEquationNumber = (_ n: Int) -> String

  /// The view's block rendering mode.
  public enum BlockMode {

    /// Block equations are ignored and always rendered inline.
    case alwaysInline

    /// Blocks are rendered as text with newlines.
    case blockText

    /// Blocks are rendered as views.
    case blockViews
  }

  /// The view's equation number mode.
  public enum EquationNumberMode {

    /// The view should not number named block equations.
    case none

    /// The view should number named block equations on the left side.
    case left

    /// The view should number named block equations on the right side.
    case right
  }

  /// The view's error mode.
  public enum ErrorMode {

    /// The rendered image should be displayed (if available).
    case rendered

    /// The original LaTeX input should be displayed.
    case original

    /// The error text should be displayed.
    case error

    /// Render the equation leniently (keep MathJax's `noerrors`/`noundefined`
    /// extensions loaded) and display MathJax's error text in red beneath the
    /// rendered output when something fails to parse. Brainblast addition.
    case renderedWithDiagnostic
  }

  /// The view's rendering mode.
  public enum ParsingMode {

    /// Render the entire text as the equation.
    case all

    /// Find equations in the text and only render the equations.
    case onlyEquations
  }

  /// The view's rendering style.
  public enum RenderingStyle {

    /// The view remains empty until its finished rendering.
    case empty

    /// The view displays the input text until it's finished rendering.
    case original

    /// The view displays a redacted version of the view until it's finished
    /// rendering.
    case redactedOriginal

    /// The view displays a progress view until it's finished rendering.
    case progress

    /// The view blocks on the main thread until it's finished rendering.
    case wait
  }

  /// The view's block alignment.
  public enum BlockAlignment {

    /// Block equations are aligned to the leading edge.
    case leading

    /// Block equations are centered.
    case center

    /// Block equations are aligned to the trailing edge.
    case trailing
  }

}

// MARK: - Render Invalidation

extension LaTeX {

  /// Tracks the last input/environment tuple used to render this view,
  /// enabling automatic re-render when any parameter changes.
  struct RenderInvalidationKey: Equatable {
    let latex: String
    let unencodeHTML: Bool
    let parsingMode: ParsingMode
    let processEscapes: Bool
    let errorMode: ErrorMode
    let xHeight: CGFloat
    let displayScale: CGFloat
  }

}

// MARK: - Standard Configuration

extension LaTeX {

  public enum ConfigurationDefaults {
    public static let displayScale: CGFloat = 2.0
  }

  /// Applies the standard Brainblast LaTeX configuration with consistent rendering settings.
  ///
  /// This configuration includes:
  /// - Fixed x-height for consistent sizing
  /// - Fixed display scale for consistent rendering
  /// - Equation-only parsing mode
  /// - Block views rendering mode
  /// - Synchronous rendering (wait mode)
  /// - Custom block alignment
  ///
  /// - Parameters:
  ///   - font: The font to use for rendering
  ///   - fixedXHeightValue: The fixed x-height value for consistent sizing
  ///   - fixedDisplayScale: The fixed display scale (defaults to 2.0)
  ///   - latexBlockAlignment: The alignment for block equations (defaults to .center)
  /// - Returns: A configured LaTeX view
  public func standardConfiguration(
    font: Font,
    fixedXHeightValue: CGFloat,
    fixedDisplayScale: CGFloat = ConfigurationDefaults.displayScale,
    latexBlockAlignment: BlockAlignment = .center
  ) -> some View {
    self
      .font(font)
      .fixedXHeight(fixedXHeightValue)
      .fixedDisplayScale(fixedDisplayScale)
      .parsingMode(.onlyEquations)
      .blockMode(.blockViews)
      .renderingStyle(.wait)
      .blockAlignment(latexBlockAlignment)
  }

  #if os(iOS) || os(visionOS)
    /// Applies the standard Brainblast LaTeX configuration using a UIFont.
    ///
    /// - Parameters:
    ///   - font: The UIFont to use for rendering
    ///   - fixedXHeightValue: The fixed x-height value for consistent sizing
    ///   - fixedDisplayScale: The fixed display scale (defaults to 2.0)
    ///   - latexBlockAlignment: The alignment for block equations (defaults to .center)
    /// - Returns: A configured LaTeX view
    public func standardConfiguration(
      font: UIFont,
      fixedXHeightValue: CGFloat,
      fixedDisplayScale: CGFloat = ConfigurationDefaults.displayScale,
      latexBlockAlignment: BlockAlignment = .center
    ) -> some View {
      self
        .font(font)
        .fixedXHeight(fixedXHeightValue)
        .fixedDisplayScale(fixedDisplayScale)
        .parsingMode(.onlyEquations)
        .blockMode(.blockViews)
        .renderingStyle(.wait)
        .blockAlignment(latexBlockAlignment)
    }
  #else
    /// Applies the standard Brainblast LaTeX configuration using an NSFont.
    ///
    /// - Parameters:
    ///   - font: The NSFont to use for rendering
    ///   - fixedXHeightValue: The fixed x-height value for consistent sizing
    ///   - fixedDisplayScale: The fixed display scale (defaults to 2.0)
    ///   - latexBlockAlignment: The alignment for block equations (defaults to .center)
    /// - Returns: A configured LaTeX view
    public func standardConfiguration(
      font: NSFont,
      fixedXHeightValue: CGFloat,
      fixedDisplayScale: CGFloat = ConfigurationDefaults.displayScale,
      latexBlockAlignment: BlockAlignment = .center
    ) -> some View {
      self
        .font(font)
        .fixedXHeight(fixedXHeightValue)
        .fixedDisplayScale(fixedDisplayScale)
        .parsingMode(.onlyEquations)
        .blockMode(.blockViews)
        .renderingStyle(.wait)
        .blockAlignment(latexBlockAlignment)
    }
  #endif

}
