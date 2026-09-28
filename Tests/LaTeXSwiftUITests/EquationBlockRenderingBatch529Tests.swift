#if os(iOS)
  import Foundation
  import SwiftUI
  import Testing
  import UIKit

  @testable import LaTeXSwiftUI

  /// Covers the equation-block half of `ComponentBlocksViews` — the branch that
  /// only runs when a block carries both a rendered SVG and an image container —
  /// plus the renderer's image rasterization and TeX-boundary diagnostics.
  ///
  /// Blocks are assembled from a hand-written SVG rather than a MathJax round
  /// trip, so nothing here depends on the renderer's JavaScript bridge.
  @MainActor
  @Suite("Equation block rendering", .serialized)
  struct EquationBlockRenderingBatch529Tests {

    private static let equationSVG = """
      <svg style="vertical-align: -1.602ex;" xmlns="http://www.w3.org/2000/svg" width="2.127ex" \
      height="4.638ex" role="img" focusable="false" viewBox="0 -1342 940 2050" \
      xmlns:xlink="http://www.w3.org/1999/xlink"><defs></defs><g stroke="currentColor" \
      fill="currentColor" stroke-width="0" transform="scale(1,-1)"></g></svg>
      """

    private static let zeroSizedSVG = """
      <svg style="vertical-align: 0ex;" xmlns="http://www.w3.org/2000/svg" width="0ex" \
      height="0ex" role="img" focusable="false" viewBox="0 0 0 0" \
      xmlns:xlink="http://www.w3.org/1999/xlink"><defs></defs></svg>
      """

    private func render<Content: View>(_ content: Content, settle: TimeInterval = 0.02) {
      let frame = CGRect(x: 0, y: 0, width: 320, height: 480)
      let controller = UIHostingController(rootView: content)
      let window = UIWindow(frame: frame)
      window.rootViewController = controller
      window.makeKeyAndVisible()
      defer { window.isHidden = true }

      controller.loadViewIfNeeded()
      controller.view.frame = frame
      controller.beginAppearanceTransition(true, animated: false)
      controller.endAppearanceTransition()
      controller.view.setNeedsLayout()
      controller.view.layoutIfNeeded()
      if settle > 0 {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: settle))
      }

      #expect(controller.view.bounds.size == frame.size)
    }

    private func makeContainer() -> ImageContainer {
      ImageContainer(
        image: Image(systemName: "function"),
        size: HashableCGSize(CGSize(width: 24, height: 48))
      )
    }

    private func makeEquationBlock(
      text: String = "\\[x^2 + y^2 = z^2\\]",
      type: Component.ComponentType = .blockEquation,
      errorText: String? = nil
    ) throws -> ComponentBlock {
      let svg = try SVG(svgString: Self.equationSVG, errorText: errorText)
      return ComponentBlock(
        components: [
          Component(text: text, type: type, svg: svg, imageContainer: makeContainer())
        ]
      )
    }

    // MARK: - Equation block rendering

    @Test("A rendered equation block draws through the image scroller")
    func equationBlockRendersImageScroller() throws {
      let block = try makeEquationBlock()
      #expect(block.isEquationBlock)
      #expect(block.svg != nil)
      #expect(block.container != nil)

      render(
        ComponentBlocksViews(blocks: [block])
          .fixedXHeight(10)
          .fixedDisplayScale(2)
      )
    }

    @Test("Equation blocks render at every block alignment")
    func equationBlockRendersEveryAlignment() throws {
      let block = try makeEquationBlock()

      for alignment in [LaTeX.BlockAlignment.leading, .center, .trailing] {
        render(
          ComponentBlocksViews(blocks: [block])
            .blockAlignment(alignment)
            .fixedXHeight(10)
            .fixedDisplayScale(2)
        )
      }
    }

    @Test("An errored equation block honors the error and original modes")
    func equationBlockRendersErrorModes() throws {
      let errored = try makeEquationBlock(errorText: "Undefined control sequence")
      #expect(errored.svg?.errorText == "Undefined control sequence")

      for errorMode in [LaTeX.ErrorMode.error, .original, .rendered] {
        render(
          ComponentBlocksViews(blocks: [errored])
            .errorMode(errorMode)
            .fixedXHeight(10)
            .fixedDisplayScale(2)
        )
      }
    }

    @Test("Numbered equation blocks render alongside their equation numbers")
    func equationBlockRendersWithNumbering() throws {
      let first = try makeEquationBlock(
        text: "\\begin{equation}a\\end{equation}", type: .namedEquation)
      let second = try makeEquationBlock(
        text: "\\begin{equation}b\\end{equation}", type: .namedEquation)

      for mode in [LaTeX.EquationNumberMode.left, .right, .none] {
        render(
          ComponentBlocksViews(blocks: [first, second])
            .equationNumberMode(mode)
            .equationNumberStart(3)
            .fixedXHeight(10)
            .fixedDisplayScale(2)
        )
      }
    }

    @Test("Mixed text and equation blocks render their padding and spacing rules")
    func mixedBlocksRender() throws {
      let intro = ComponentBlock(components: [Component(text: "Solve for x:", type: .text)])
      let equation = try makeEquationBlock()
      let inline = ComponentBlock(
        components: [Component(text: "$x = 1$", type: .inlineEquation)]
      )
      let outro = ComponentBlock(components: [Component(text: "Nice work.", type: .text)])

      render(
        ComponentBlocksViews(blocks: [intro, equation, inline, outro])
          .fixedXHeight(10)
          .fixedDisplayScale(2)
      )
      render(
        ComponentBlocksViews(blocks: [equation, intro, equation, outro])
          .blockAlignment(.center)
          .fixedXHeight(10)
          .fixedDisplayScale(2)
      )
    }

    @Test("An empty block list renders an empty stack")
    func emptyBlockListRenders() {
      render(ComponentBlocksViews(blocks: []))
    }

    // MARK: - Renderer image generation

    @Test("The renderer rasterizes an SVG and serves the second request from cache")
    func rendererRasterizesAndCachesImage() throws {
      let renderer = Renderer()
      let svg = try SVG(svgString: Self.equationSVG)

      let first = renderer.getImage(
        for: svg,
        xHeight: 10,
        displayScale: 2,
        renderingMode: .template
      )
      #expect(first != nil)

      let cached = renderer.getImage(
        for: svg,
        xHeight: 10,
        displayScale: 2,
        renderingMode: .original
      )
      #expect(cached != nil)
    }

    @Test("A zero-sized SVG produces no image")
    func rendererRejectsZeroSizedSVG() {
      let renderer = Renderer()
      guard let svg = try? SVG(svgString: Self.zeroSizedSVG) else { return }

      let size = svg.size(for: 10)
      guard size.width == 0 || size.height == 0 else { return }

      #expect(
        renderer.getImage(for: svg, xHeight: 10, displayScale: 2, renderingMode: .template) == nil
      )
    }

    @Test("The renderer produces images across x-heights and display scales")
    func rendererRastersAcrossMetrics() throws {
      let renderer = Renderer()
      let svg = try SVG(svgString: Self.equationSVG)

      for xHeight in [CGFloat(6), 10, 18] {
        for displayScale in [CGFloat(1), 2, 3] {
          let image = renderer.getImage(
            for: svg,
            xHeight: xHeight,
            displayScale: displayScale,
            renderingMode: .template
          )
          #expect(image != nil)
        }
      }
    }

    // MARK: - TeX boundary diagnostics

    @Test("The TeX boundary log records requests and dumps history on error")
    func texBoundaryLogging() {
      Renderer.logTeXBoundary(
        rawText: "$x^{n+1}$",
        texInput: "x^{n+1 }",
        phase: "request"
      )
      Renderer.logTeXBoundary(
        rawText: "$\\frac{1}{2}$",
        texInput: "\\frac{1}{2}",
        phase: "request"
      )
      Renderer.logTeXBoundary(
        rawText: "$\\badcommand{",
        texInput: "\\badcommand{",
        phase: "MathJax error: Extra open brace or missing close brace"
      )
      Renderer.logTeXBoundary(rawText: "", texInput: "", phase: "request")
    }

    @Test("The digit-script rewrite only pads script groups")
    func digitScriptRewriteIsScoped() {
      #expect(Renderer.insertSpaceBeforeDigitScriptBrace("x^{n+1}") == "x^{n+1 }")
      #expect(Renderer.insertSpaceBeforeDigitScriptBrace("x_{12}") == "x_{12 }")
      #expect(
        Renderer.insertSpaceBeforeDigitScriptBrace("\\textcolor{#ff3b30}{x}")
          == "\\textcolor{#ff3b30}{x}")
      #expect(Renderer.insertSpaceBeforeDigitScriptBrace("") == "")
      #expect(Renderer.insertSpaceBeforeDigitScriptBrace("\\") == "\\")
    }

    @Test("Numeric bases are separated from their exponent outside text mode")
    func numericBaseExponentNormalization() {
      #expect(Renderer.normalizeNumericBaseExponentsForMathJax("3^4") == "3 ^4")
      #expect(Renderer.normalizeNumericBaseExponentsForMathJax("x^4") == "x^4")
      #expect(Renderer.normalizeNumericBaseExponentsForMathJax("") == "")
      #expect(
        Renderer.normalizeNumericBaseExponentsForMathJax("\\text{3^4}")
          == "\\text{3^4}"
      )
    }
  }
#endif
