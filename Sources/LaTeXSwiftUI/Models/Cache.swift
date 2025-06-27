//
//  Cache.swift
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

import CryptoKit
import Foundation
import MathJaxSwift

internal protocol CacheKey: Codable {
  
  /// The key type used to identify the cache key in storage.
  static var keyType: String { get }
  
  /// A key to use if encoding fails.
  var fallbackKey: String { get }
  
}

extension CacheKey {
  
  /// The key to use in the cache.
  internal func key() -> String {
    do {
      let data = try JSONEncoder().encode(self)
      let hashedData = SHA256.hash(data: data)
      return hashedData.compactMap { String(format: "%02x", $0) }.joined() + "-" + Self.keyType
    }
    catch {
      return fallbackKey + "-" + Self.keyType
    }
  }
  
}

internal class Cache {
  
  // MARK: Types
  
  /// An SVG cache key.
  struct SVGCacheKey: CacheKey {
    static let keyType: String = "svg"
    let componentText: String
    let conversionOptions: ConversionOptions
    let texOptions: TeXInputProcessorOptions
    internal var fallbackKey: String { componentText }
  }
  
  /// An image cache key.
  struct ImageCacheKey: CacheKey {
    static let keyType: String = "image"
    let svg: SVG
    let xHeight: CGFloat
    internal var fallbackKey: String { String(data: svg.data, encoding: .utf8) ?? "" }
  }
  
  // MARK: Static properties
  
  /// The shared cache.
  static let shared = Cache()
  
  // MARK: Public properties
  
  /// The renderer's data cache.
  let dataCache: NSCache<NSString, NSData> = NSCache()
  
  /// The renderer's image cache.
  let imageCache: NSCache<NSString, _Image> = NSCache()
  
  // MARK: Private properties
  
  /// The data cache queue.
  private let dataCacheQueue = DispatchQueue(label: "latexswiftui.cache.data")
  
  /// The image cache queue.
  private let imageCacheQueue = DispatchQueue(label: "latexswiftui.cache.image")
  
  /// Counter for consecutive rendering failures.
  private var _consecutiveFailures: Int = 0
  private let failureCountQueue = DispatchQueue(label: "latexswiftui.cache.failures")
  
  /// The maximum number of consecutive failures before clearing caches.
  private let maxConsecutiveFailures = 3
  
}

// MARK: Public methods

extension Cache {
  
  /// Safely access the cache value for the given key.
  ///
  /// - Parameter key: The key of the value to get.
  /// - Returns: A value.
  func dataCacheValue(for key: SVGCacheKey) -> Data? {
    return dataCacheQueue.sync { [weak self] in
      guard let self = self else { return nil }
      return self.dataCache.object(forKey: key.key() as NSString) as Data?
    }
  }
  
  /// Safely sets the cache value.
  ///
  /// - Parameters:
  ///   - value: The value to set.
  ///   - key: The value's key.
  func setDataCacheValue(_ value: Data, for key: SVGCacheKey) {
    dataCacheQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self.dataCache.setObject(value as NSData, forKey: key.key() as NSString)
    }
  }
  
  /// Safely access the cache value for the given key.
  ///
  /// - Parameter key: The key of the value to get.
  /// - Returns: A value.
  func imageCacheValue(for key: ImageCacheKey) -> _Image? {
    return imageCacheQueue.sync { [weak self] in
      guard let self = self else { return nil }
      return self.imageCache.object(forKey: key.key() as NSString)
    }
  }
  
  /// Safely sets the cache value.
  ///
  /// - Parameters:
  ///   - value: The value to set.
  ///   - key: The value's key.
  func setImageCacheValue(_ value: _Image, for key: ImageCacheKey) {
    imageCacheQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self.imageCache.setObject(value, forKey: key.key() as NSString)
    }
  }
  
  /// Completely clears both caches.
  func clearAllCaches() {
    dataCacheQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self.dataCache.removeAllObjects()
    }
    
    imageCacheQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self.imageCache.removeAllObjects()
    }
    
    resetFailureCount()
    NSLog("LaTeXSwiftUI: Cleared all caches due to rendering issues")
  }
  
  /// Records a rendering failure and clears caches if threshold is reached.
  ///
  /// - Returns: Whether caches were cleared due to consecutive failures.
  func recordRenderingFailure() -> Bool {
    return failureCountQueue.sync { [weak self] in
      guard let self = self else { return false }
      self._consecutiveFailures += 1
      
      if self._consecutiveFailures >= self.maxConsecutiveFailures {
        DispatchQueue.global(qos: .utility).async { [weak self] in
          self?.clearAllCaches()
        }
        return true
      }
      return false
    }
  }
  
  /// Records a successful rendering operation.
  func recordRenderingSuccess() {
    resetFailureCount()
  }
  
  /// Resets the consecutive failure counter.
  private func resetFailureCount() {
    failureCountQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self._consecutiveFailures = 0
    }
  }
  
  /// Gets the current consecutive failure count.
  var consecutiveFailures: Int {
    return failureCountQueue.sync { [weak self] in
      return self?._consecutiveFailures ?? 0
    }
  }
  
}
