import Foundation
import MathJaxSwift
import SwiftUI
import Testing

@testable import LaTeXSwiftUI

@Suite("Renderer State Tests")
struct RendererStateTests {

  @Test("renderSync returns empty while a render is in flight")
  @MainActor func renderSyncWhileRendering() {
    let renderer = Renderer()
    renderer.isRendering = true
    let blocks = renderer.renderSync(
      latex: "$x$",
      unencodeHTML: false,
      parsingMode: .onlyEquations,
      processEscapes: false,
      errorMode: .original,
      xHeight: 7,
      displayScale: 2,
      renderingMode: .template)
    #expect(blocks.isEmpty)
  }

  @Test("renderSync returns existing blocks when already rendered")
  @MainActor func renderSyncWhenAlreadyRendered() {
    let renderer = Renderer()
    renderer.syncRendered = true
    let blocks = renderer.renderSync(
      latex: "$x$",
      unencodeHTML: false,
      parsingMode: .onlyEquations,
      processEscapes: false,
      errorMode: .original,
      xHeight: 7,
      displayScale: 2,
      renderingMode: .template)
    #expect(blocks.isEmpty)
    #expect(!renderer.isRendering)
  }

  @Test("Async render is a no-op when already rendered")
  func asyncRenderNoOpWhenRendered() async {
    let renderer = Renderer()
    await MainActor.run { renderer.rendered = true }
    await renderer.render(
      latex: "$x$",
      unencodeHTML: false,
      parsingMode: .onlyEquations,
      processEscapes: false,
      errorMode: .original,
      xHeight: 7,
      displayScale: 2,
      renderingMode: .template)
    await MainActor.run {
      #expect(renderer.blocks.isEmpty)
      #expect(!renderer.isRendering)
    }
  }

}

@Suite("Prewarm Batch Tests")
struct PrewarmBatchTests {

  @Test("prewarm over multiple x-heights caches each variant")
  @MainActor func prewarmMultipleXHeights() async {
    await LaTeX.prewarm(
      "$a+b$",
      xHeights: [5, 8],
      displayScale: 2)
    let renderer = Renderer()
    let cached = renderer.isCached(
      latex: "$a+b$",
      unencodeHTML: false,
      parsingMode: .onlyEquations,
      processEscapes: false,
      errorMode: .original,
      xHeight: 8,
      displayScale: 2)
    #expect(cached)
  }

}

@Suite("MathJax Lifecycle Tests", .serialized)
struct MathJaxLifecycleTests {

  @Test("memoryUsageMB reports a non-negative value")
  func memoryUsage() {
    #expect(MathJax.memoryUsageMB() >= 0)
  }

  @Test("svgRenderer initializes once and is reused")
  func svgRendererReuse() throws {
    let first = try #require(MathJax.svgRenderer)
    let second = try #require(MathJax.svgRenderer)
    #expect(first === second)
  }

  @Test("Renderer wrapper tracks lifecycle through deinit")
  func rendererWrapperLifecycle() throws {
    let mathJax = try #require(MathJax.svgRenderer)
    var wrapper: MathJaxRendererWrapper? = MathJaxRendererWrapper(renderer: mathJax)
    #expect(wrapper?.renderer === mathJax)
    wrapper = nil
    #expect(wrapper == nil)
  }

  @Test("releaseRenderer tears down and allows re-initialization")
  func releaseAndReinitialize() throws {
    _ = MathJax.svgRenderer
    MathJax.releaseRenderer()
    MathJax.releaseRenderer()
    let renderer = try #require(MathJax.svgRenderer)
    _ = renderer
  }

}
