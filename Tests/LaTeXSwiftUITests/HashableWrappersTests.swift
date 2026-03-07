import Testing
import Foundation
import CoreGraphics
@testable import LaTeXSwiftUI

@Suite("HashableCGRect Tests")
struct HashableCGRectTests {

    @Test("Initializes with CGRect")
    func initialization() {
        let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
        let hashable = HashableCGRect(rect)
        #expect(hashable.rect == rect)
    }

    @Test("Equal rects produce equal hashes")
    func equalRectsEqualHashes() {
        let a = HashableCGRect(CGRect(x: 1, y: 2, width: 3, height: 4))
        let b = HashableCGRect(CGRect(x: 1, y: 2, width: 3, height: 4))
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Different rects produce different hashes")
    func differentRectsDifferentHashes() {
        let a = HashableCGRect(CGRect(x: 1, y: 2, width: 3, height: 4))
        let b = HashableCGRect(CGRect(x: 5, y: 6, width: 7, height: 8))
        #expect(a.hashValue != b.hashValue)
    }

    @Test("Equatable conformance works for equal rects")
    func equatableEqual() {
        let a = HashableCGRect(CGRect(x: 10, y: 20, width: 30, height: 40))
        let b = HashableCGRect(CGRect(x: 10, y: 20, width: 30, height: 40))
        #expect(a == b)
    }

    @Test("Equatable conformance works for different rects")
    func equatableNotEqual() {
        let a = HashableCGRect(CGRect(x: 10, y: 20, width: 30, height: 40))
        let b = HashableCGRect(CGRect(x: 10, y: 20, width: 30, height: 50))
        #expect(a != b)
    }

    @Test("Zero rect hashes consistently")
    func zeroRect() {
        let a = HashableCGRect(.zero)
        let b = HashableCGRect(.zero)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Negative values hash correctly")
    func negativeValues() {
        let a = HashableCGRect(CGRect(x: -10, y: -20, width: 30, height: 40))
        let b = HashableCGRect(CGRect(x: -10, y: -20, width: 30, height: 40))
        #expect(a == b)
    }

    @Test("HashableCGRect can be used as dictionary key")
    func dictionaryKey() {
        let key = HashableCGRect(CGRect(x: 1, y: 2, width: 3, height: 4))
        var dict: [HashableCGRect: String] = [:]
        dict[key] = "test"
        #expect(dict[key] == "test")
    }

    @Test("HashableCGRect can be used in a Set")
    func setUsage() {
        let a = HashableCGRect(CGRect(x: 1, y: 2, width: 3, height: 4))
        let b = HashableCGRect(CGRect(x: 1, y: 2, width: 3, height: 4))
        let c = HashableCGRect(CGRect(x: 5, y: 6, width: 7, height: 8))
        let set: Set<HashableCGRect> = [a, b, c]
        #expect(set.count == 2)
    }

    @Test("Codable round-trip preserves values")
    func codableRoundTrip() throws {
        let original = HashableCGRect(CGRect(x: 1.5, y: -2.5, width: 100, height: 200))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HashableCGRect.self, from: data)
        #expect(decoded == original)
    }
}

@Suite("HashableCGSize Tests")
struct HashableCGSizeTests {

    @Test("Initializes with CGSize")
    func initialization() {
        let size = CGSize(width: 100, height: 200)
        let hashable = HashableCGSize(size)
        #expect(hashable.size == size)
    }

    @Test("Equal sizes produce equal hashes")
    func equalSizesEqualHashes() {
        let a = HashableCGSize(CGSize(width: 100, height: 200))
        let b = HashableCGSize(CGSize(width: 100, height: 200))
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Different sizes produce different hashes")
    func differentSizesDifferentHashes() {
        let a = HashableCGSize(CGSize(width: 100, height: 200))
        let b = HashableCGSize(CGSize(width: 300, height: 400))
        #expect(a.hashValue != b.hashValue)
    }

    @Test("Equatable conformance works")
    func equatable() {
        let a = HashableCGSize(CGSize(width: 50, height: 75))
        let b = HashableCGSize(CGSize(width: 50, height: 75))
        #expect(a == b)
    }

    @Test("Different widths are not equal")
    func differentWidthNotEqual() {
        let a = HashableCGSize(CGSize(width: 50, height: 75))
        let b = HashableCGSize(CGSize(width: 51, height: 75))
        #expect(a != b)
    }

    @Test("Different heights are not equal")
    func differentHeightNotEqual() {
        let a = HashableCGSize(CGSize(width: 50, height: 75))
        let b = HashableCGSize(CGSize(width: 50, height: 76))
        #expect(a != b)
    }

    @Test("Zero size hashes consistently")
    func zeroSize() {
        let a = HashableCGSize(.zero)
        let b = HashableCGSize(.zero)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("HashableCGSize can be used as dictionary key")
    func dictionaryKey() {
        let key = HashableCGSize(CGSize(width: 10, height: 20))
        var dict: [HashableCGSize: Int] = [:]
        dict[key] = 42
        #expect(dict[key] == 42)
    }

    @Test("HashableCGSize can be used in a Set")
    func setUsage() {
        let a = HashableCGSize(CGSize(width: 10, height: 20))
        let b = HashableCGSize(CGSize(width: 10, height: 20))
        let c = HashableCGSize(CGSize(width: 30, height: 40))
        let set: Set<HashableCGSize> = [a, b, c]
        #expect(set.count == 2)
    }
}
