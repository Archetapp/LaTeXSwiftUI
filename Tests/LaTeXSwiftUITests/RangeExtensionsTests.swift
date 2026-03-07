import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("Range+Extensions Tests")
struct RangeExtensionsTests {

    @Test("isSubrange returns true for proper subrange")
    func properSubrange() {
        let text = "Hello, World!"
        let outer = text.startIndex..<text.endIndex
        let inner = text.index(text.startIndex, offsetBy: 2)..<text.index(text.startIndex, offsetBy: 5)
        #expect(inner.isSubrange(of: outer) == true)
    }

    @Test("isSubrange returns false for identical ranges")
    func identicalRanges() {
        let text = "Hello"
        let range = text.startIndex..<text.endIndex
        #expect(range.isSubrange(of: range) == false)
    }

    @Test("isSubrange returns false when lower bound is before outer")
    func lowerBoundBefore() {
        let text = "Hello, World!"
        let outer = text.index(text.startIndex, offsetBy: 2)..<text.index(text.startIndex, offsetBy: 8)
        let test = text.startIndex..<text.index(text.startIndex, offsetBy: 5)
        #expect(test.isSubrange(of: outer) == false)
    }

    @Test("isSubrange returns false when upper bound is after outer")
    func upperBoundAfter() {
        let text = "Hello, World!"
        let outer = text.index(text.startIndex, offsetBy: 2)..<text.index(text.startIndex, offsetBy: 8)
        let test = text.index(text.startIndex, offsetBy: 3)..<text.endIndex
        #expect(test.isSubrange(of: outer) == false)
    }

    @Test("isSubrange returns true when touching outer bounds from inside")
    func touchingOuterBoundsFromInside() {
        let text = "Hello, World!"
        let outer = text.startIndex..<text.endIndex
        let inner = text.startIndex..<text.index(text.startIndex, offsetBy: 5)
        #expect(inner.isSubrange(of: outer) == true)
    }

    @Test("isSubrange returns true for single-character subrange")
    func singleCharacterSubrange() {
        let text = "Hello"
        let outer = text.startIndex..<text.endIndex
        let inner = text.index(text.startIndex, offsetBy: 2)..<text.index(text.startIndex, offsetBy: 3)
        #expect(inner.isSubrange(of: outer) == true)
    }
}
