import Testing
import Foundation
import MathJaxSwift
@testable import LaTeXSwiftUI

@Suite("Cache Tests")
struct CacheTests {

    // MARK: - CacheKey Hashing

    @Test("SVGCacheKey with same text produces consistent key suffix")
    func svgCacheKeyConsistentSuffix() {
        let key = Cache.SVGCacheKey(
            componentText: "x^2",
            conversionOptions: ConversionOptions(display: false),
            texOptions: TeXInputProcessorOptions()
        )
        #expect(key.key().hasSuffix("-svg"))
    }

    @Test("SVGCacheKey fallbackKey returns component text")
    func svgCacheKeyFallback() {
        let key = Cache.SVGCacheKey(
            componentText: "x^2",
            conversionOptions: ConversionOptions(display: false),
            texOptions: TeXInputProcessorOptions()
        )
        #expect(key.fallbackKey == "x^2")
    }

    @Test("SVGCacheKey keyType is svg")
    func svgCacheKeyType() {
        #expect(Cache.SVGCacheKey.keyType == "svg")
    }

    @Test("ImageCacheKey keyType is image")
    func imageCacheKeyType() {
        #expect(Cache.ImageCacheKey.keyType == "image")
    }

    @Test("CacheKey key includes keyType suffix")
    func cacheKeyIncludesTypeSuffix() {
        let key = Cache.SVGCacheKey(
            componentText: "x",
            conversionOptions: ConversionOptions(display: false),
            texOptions: TeXInputProcessorOptions()
        )
        #expect(key.key().hasSuffix("-svg"))
    }

    @Test("CacheKey key is non-empty")
    func cacheKeyNonEmpty() {
        let key = Cache.SVGCacheKey(
            componentText: "test",
            conversionOptions: ConversionOptions(display: false),
            texOptions: TeXInputProcessorOptions()
        )
        #expect(!key.key().isEmpty)
    }

    // MARK: - Cache Data Operations

    @Test("Data cache stores and retrieves values via NSCache directly")
    func dataCacheStoreAndRetrieve() {
        let cache = Cache()
        let cacheKey = "direct_test_key" as NSString
        let data = "test data".data(using: .utf8)! as NSData

        cache.dataCache.setObject(data, forKey: cacheKey)

        let retrieved = cache.dataCache.object(forKey: cacheKey) as Data?
        #expect(retrieved == data as Data)
    }

    @Test("Data cache returns nil for missing key")
    func dataCacheMissingKey() {
        let cache = Cache()
        let key = Cache.SVGCacheKey(
            componentText: "nonexistent_\(UUID().uuidString)",
            conversionOptions: ConversionOptions(display: false),
            texOptions: TeXInputProcessorOptions()
        )

        let result = cache.dataCacheValue(for: key)
        #expect(result == nil)
    }

    // MARK: - Failure Tracking

    @Test("consecutiveFailures starts at zero")
    func initialFailureCountIsZero() {
        let cache = Cache()
        #expect(cache.consecutiveFailures == 0)
    }

    @Test("recordRenderingFailure increments failure count")
    func recordFailureIncrements() {
        let cache = Cache()
        _ = cache.recordRenderingFailure()
        Thread.sleep(forTimeInterval: 0.05)
        #expect(cache.consecutiveFailures >= 1)
    }

    @Test("recordRenderingSuccess resets failure count")
    func recordSuccessResets() {
        let cache = Cache()
        _ = cache.recordRenderingFailure()
        _ = cache.recordRenderingFailure()
        Thread.sleep(forTimeInterval: 0.05)
        cache.recordRenderingSuccess()
        Thread.sleep(forTimeInterval: 0.05)
        #expect(cache.consecutiveFailures == 0)
    }

    @Test("recordRenderingFailure returns true when threshold reached")
    func failureThresholdClearsCaches() {
        let cache = Cache()
        _ = cache.recordRenderingFailure()
        _ = cache.recordRenderingFailure()
        let cleared = cache.recordRenderingFailure()
        #expect(cleared == true)
    }

    @Test("recordRenderingFailure returns false below threshold")
    func belowThresholdDoesNotClear() {
        let cache = Cache()
        let cleared = cache.recordRenderingFailure()
        #expect(cleared == false)
    }

    // MARK: - Clear All Caches

    @Test("clearAllCaches removes all cached data")
    func clearAllCachesRemovesData() {
        let cache = Cache()
        let key = Cache.SVGCacheKey(
            componentText: "clear_test_\(UUID().uuidString)",
            conversionOptions: ConversionOptions(display: false),
            texOptions: TeXInputProcessorOptions()
        )
        let data = "data to clear".data(using: .utf8)!
        cache.setDataCacheValue(data, for: key)

        Thread.sleep(forTimeInterval: 0.1)

        cache.clearAllCaches()

        Thread.sleep(forTimeInterval: 0.1)

        let retrieved = cache.dataCacheValue(for: key)
        #expect(retrieved == nil)
    }
}
