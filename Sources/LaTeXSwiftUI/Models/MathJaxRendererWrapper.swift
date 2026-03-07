//
//  MathJaxRendererWrapper.swift
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

/// Wraps a MathJax renderer instance to track lifecycle and memory usage
/// via reference counting and diagnostic logging.
internal final class MathJaxRendererWrapper {

  let renderer: MathJax

  private static var totalCreatedCount = 0
  private static var activeCount = 0
  private let instanceId: Int

  init(renderer: MathJax) {
    self.renderer = renderer
    Self.totalCreatedCount += 1
    Self.activeCount += 1
    self.instanceId = Self.totalCreatedCount
    let memory = MathJax.memoryUsageMB()
    NSLog("LaTeXSwiftUI: MathJaxRendererWrapper #\(instanceId) created (active: \(Self.activeCount), memory: \(memory) MB)")
  }

  deinit {
    Self.activeCount -= 1
    let memory = MathJax.memoryUsageMB()
    NSLog("LaTeXSwiftUI: MathJaxRendererWrapper #\(instanceId) DEALLOCATED (remaining: \(Self.activeCount), memory: \(memory) MB)")
  }

}
