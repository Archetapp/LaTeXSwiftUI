#if os(iOS)
import SwiftUI
import Testing
import UIKit

@testable import LaTeXSwiftUI

@MainActor
@Suite("Critical LaTeX view surfaces", .serialized)
struct CriticalViewSurfaceCoverageTests {

  private func render<Content: View>(_ content: Content) {
    let frame = CGRect(x: 0, y: 0, width: 320, height: 240)
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
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))

    #expect(controller.view.bounds.size == frame.size)
  }

  @Test("text and stacked block renderers exercise inline and block-shaped input")
  func componentBlockRenderers() {
    let blocks = [
      ComponentBlock(components: [Component(text: "Before ", type: .text)]),
      ComponentBlock(components: [Component(text: "$x + 1$", type: .inlineEquation)]),
      ComponentBlock(components: [Component(text: " after", type: .text)]),
    ]

    render(
      VStack {
        ComponentBlocksText(blocks: blocks)
        ComponentBlocksText(blocks: blocks, forceInline: true)
        ComponentBlocksViews(blocks: blocks).blockAlignment(.leading)
        ComponentBlocksViews(blocks: blocks).blockAlignment(.center)
        ComponentBlocksViews(blocks: blocks).blockAlignment(.trailing)
      }
      .fixedXHeight(10)
      .fixedDisplayScale(2)
    )
  }

  @Test("equation numbering renders every mode and side")
  func equationNumberModes() {
    render(
      VStack {
        HStack {
          EquationNumber(blockIndex: 2, side: .left)
          EquationNumber(blockIndex: 2, side: .right)
        }
        .equationNumberMode(.left)

        HStack {
          EquationNumber(blockIndex: 3, side: .left)
          EquationNumber(blockIndex: 3, side: .right)
        }
        .equationNumberMode(.right)

        HStack {
          EquationNumber(blockIndex: 4, side: .left)
          EquationNumber(blockIndex: 4, side: .right)
        }
        .equationNumberMode(.none)
      }
      .equationNumberStart(5)
      .equationNumberOffset(12)
      .formatEquationNumber { "Eq. \($0)" }
    )
  }

  @Test("horizontal image scroller covers fitting and fallback configurations")
  func horizontalImageScrollerConfigurations() {
    render(
      VStack {
        HorizontalImageScroller(
          image: Image(systemName: "function"),
          size: CGSize(width: 80, height: 24),
          showsIndicators: true,
          minimumScaleFactor: 0.65
        )
        HorizontalImageScroller(
          image: Image(systemName: "sum"),
          size: CGSize(width: 1_000, height: 100),
          showsIndicators: false,
          minimumScaleFactor: -1
        )
      }
    )
  }
}
#endif
