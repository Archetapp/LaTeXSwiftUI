import Foundation
import SwiftUI
import Testing

@testable import LaTeXSwiftUI

@Suite("Renderer Cache Path Tests")
struct RendererCachePathTests {

  @Test("isCached returns false for never-rendered input")
  func isCachedFalseForNeverRenderedInput() {
    let renderer = Renderer()
    let cached = renderer.isCached(
      latex: "$\\zeta(\(UUID().uuidString))$",
      unencodeHTML: false,
      parsingMode: .onlyEquations,
      processEscapes: false,
      errorMode: .original,
      xHeight: 7,
      displayScale: 2)
    #expect(!cached)
  }

  @Test("renderSync passes text-only blocks through untouched")
  @MainActor func renderSyncPassesTextOnlyBlocksThrough() {
    let renderer = Renderer()
    let blocks = renderer.renderSync(
      latex: "plain prose with no math",
      unencodeHTML: false,
      parsingMode: .onlyEquations,
      processEscapes: false,
      errorMode: .original,
      xHeight: 7,
      displayScale: 2,
      renderingMode: .template)
    #expect(blocks.count == 1)
    #expect(blocks.first?.components.first?.svg == nil)
  }

  @Test("ImageContainer hashes by size")
  func imageContainerHashesBySize() {
    let first = ImageContainer(
      image: Image(systemName: "circle"),
      size: HashableCGSize(CGSize(width: 10, height: 10)))
    let second = ImageContainer(
      image: Image(systemName: "square"),
      size: HashableCGSize(CGSize(width: 10, height: 10)))

    var firstHasher = Hasher()
    first.hash(into: &firstHasher)
    var secondHasher = Hasher()
    second.hash(into: &secondHasher)

    #expect(firstHasher.finalize() == secondHasher.finalize())
  }

}
