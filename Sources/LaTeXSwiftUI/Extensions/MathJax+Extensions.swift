//
//  MathJax+Extensions.swift
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

#if os(iOS)
import UIKit
#endif

internal extension MathJax {

  private enum Constants {
    static let memoryCleanupPasses = 3
    static let cleanupPassInterval: TimeInterval = 0.1
    static let postReleaseMemoryCheckDelay: TimeInterval = 2.0
  }

  private static var _rendererWrapper: MathJaxRendererWrapper?
  private static var _svgRendererInitialized = false
  private static let rendererLock = NSLock()

  static var svgRenderer: MathJax? {
    get {
      rendererLock.lock()
      defer { rendererLock.unlock() }

      if !_svgRendererInitialized {
        _svgRendererInitialized = true
        let memoryBefore = memoryUsageMB()
        NSLog("LaTeXSwiftUI: Initializing MathJax renderer... (memory before: \(memoryBefore) MB)")
        do {
          let mathJax = try MathJax(preferredOutputFormat: .svg)
          _rendererWrapper = MathJaxRendererWrapper(renderer: mathJax)
          let memoryAfter = memoryUsageMB()
          let memoryDelta = memoryAfter - memoryBefore
          NSLog("LaTeXSwiftUI: MathJax initialized (memory: \(memoryAfter) MB, delta: +\(memoryDelta) MB)")
        } catch {
          NSLog("LaTeXSwiftUI: MathJax renderer initialization failed: \(error)")
          _rendererWrapper = nil
        }
      }
      return _rendererWrapper?.renderer
    }
  }

  static let renderQueue = DispatchQueue(label: "com.latexswiftui.mathjax", qos: .userInitiated)

  static func releaseRenderer() {
    NSLog("LaTeXSwiftUI: releaseRenderer() called - starting release sequence")

    Cache.shared.clearAllCaches()
    NSLog("LaTeXSwiftUI: Caches cleared synchronously")

    var wasReleased = false

    renderQueue.sync {
      autoreleasepool {
        rendererLock.lock()
        defer { rendererLock.unlock() }

        if _rendererWrapper != nil {
          _rendererWrapper = nil
          _svgRendererInitialized = false
          wasReleased = true
          NSLog("LaTeXSwiftUI: MathJax renderer wrapper set to nil")
        } else {
          NSLog("LaTeXSwiftUI: MathJax renderer wrapper was already nil")
        }
      }
    }

    if wasReleased {
      performPostReleaseCleanup()
    }
  }

  /// Runs memory cleanup passes and posts memory warning notifications.
  private static func performPostReleaseCleanup() {
    DispatchQueue.global(qos: .utility).async {
      for i in 0..<Constants.memoryCleanupPasses {
        autoreleasepool {
          Thread.sleep(forTimeInterval: Constants.cleanupPassInterval)
        }
        NSLog("LaTeXSwiftUI: Memory cleanup pass \(i + 1)/\(Constants.memoryCleanupPasses)")
      }

      let memoryAfter = Self.memoryUsageMB()
      NSLog("LaTeXSwiftUI: releaseRenderer() complete - memory: \(memoryAfter) MB")

      DispatchQueue.main.async {
        #if os(iOS)
        NotificationCenter.default.post(
          name: UIApplication.didReceiveMemoryWarningNotification,
          object: nil
        )
        NSLog("LaTeXSwiftUI: Posted memory warning notification")
        #endif
      }

      DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + Constants.postReleaseMemoryCheckDelay) {
        let delayedMemory = Self.memoryUsageMB()
        NSLog("LaTeXSwiftUI: Memory after delayed check: \(delayedMemory) MB")
      }
    }
  }

  static func memoryUsageMB() -> Int {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    return kerr == KERN_SUCCESS ? Int(info.resident_size / 1024 / 1024) : 0
  }

}
