import Testing
import Foundation
@testable import LaTeXSwiftUI

@Suite("SVG Model Tests")
struct SVGTests {

    private static let validSVGString = """
    <svg style="vertical-align: -1.602ex;" xmlns="http://www.w3.org/2000/svg" width="2.127ex" height="4.638ex" role="img" focusable="false" viewBox="0 -1342 940 2050" xmlns:xlink="http://www.w3.org/1999/xlink"><defs></defs><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"></g></svg>
    """

    // MARK: - SVG Initialization

    @Test("SVG initializes from valid SVG string")
    func svgInitFromString() throws {
        let svg = try SVG(svgString: SVGTests.validSVGString)
        #expect(svg.errorText == nil)
        #expect(svg.data.count > 0)
        #expect(svg.geometry.verticalAlignment == -1.602)
        #expect(svg.geometry.width == 2.127)
        #expect(svg.geometry.height == 4.638)
    }

    @Test("SVG initializes with error text")
    func svgInitWithErrorText() throws {
        let svg = try SVG(svgString: SVGTests.validSVGString, errorText: "Some error")
        #expect(svg.errorText == "Some error")
    }

    @Test("SVG throws on invalid SVG string missing svg element")
    func svgThrowsOnMissingSVGElement() {
        #expect(throws: SVGGeometry.ParsingError.self) {
            _ = try SVG(svgString: "<div>Not an SVG</div>")
        }
    }

    @Test("SVG throws on SVG missing geometry attributes")
    func svgThrowsOnMissingGeometry() {
        #expect(throws: SVGGeometry.ParsingError.self) {
            _ = try SVG(svgString: "<svg></svg>")
        }
    }

    // MARK: - SVG Encoding/Decoding

    @Test("SVG round-trips through JSON encoding and decoding")
    func svgRoundTrip() throws {
        let original = try SVG(svgString: SVGTests.validSVGString)
        let encoded = try original.encoded()
        let decoded = try SVG(data: encoded)

        #expect(decoded.geometry.verticalAlignment == original.geometry.verticalAlignment)
        #expect(decoded.geometry.width == original.geometry.width)
        #expect(decoded.geometry.height == original.geometry.height)
        #expect(decoded.errorText == original.errorText)
        #expect(decoded.data == original.data)
    }

    // MARK: - SVG Size Calculation

    @Test("SVG size scales with xHeight")
    func svgSizeScalesWithXHeight() throws {
        let svg = try SVG(svgString: SVGTests.validSVGString)

        let size1 = svg.size(for: 1.0)
        let size2 = svg.size(for: 2.0)

        #expect(size2.width == size1.width * 2.0)
        #expect(size2.height == size1.height * 2.0)
    }

    @Test("SVG size with zero xHeight returns zero size")
    func svgSizeWithZeroXHeight() throws {
        let svg = try SVG(svgString: SVGTests.validSVGString)
        let size = svg.size(for: 0)
        #expect(size.width == 0)
        #expect(size.height == 0)
    }

    @Test("SVG size with negative xHeight returns negative size")
    func svgSizeWithNegativeXHeight() throws {
        let svg = try SVG(svgString: SVGTests.validSVGString)
        let size = svg.size(for: -1.0)
        #expect(size.width < 0)
        #expect(size.height < 0)
    }

    // MARK: - SVG Hashable

    @Test("Identical SVGs produce equal hashes")
    func svgHashEquality() throws {
        let svg1 = try SVG(svgString: SVGTests.validSVGString)
        let svg2 = try SVG(svgString: SVGTests.validSVGString)
        #expect(svg1.hashValue == svg2.hashValue)
    }

    @Test("Identical SVGs are equal")
    func svgEquality() throws {
        let svg1 = try SVG(svgString: SVGTests.validSVGString)
        let svg2 = try SVG(svgString: SVGTests.validSVGString)
        #expect(svg1 == svg2)
    }

    // MARK: - SVG Error

    @Test("SVG encoding error case exists")
    func svgEncodingError() {
        let error = SVG.SVGError.encodingSVGData
        #expect(error == .encodingSVGData)
    }
}

@Suite("SVGGeometry Extended Tests")
struct SVGGeometryExtendedTests {

    // MARK: - parseAlignment

    @Test("parseAlignment returns nil for invalid format")
    func parseAlignmentInvalidFormat() {
        let result = SVGGeometry.parseAlignment(from: "invalid")
        #expect(result == nil)
    }

    @Test("parseAlignment handles positive values")
    func parseAlignmentPositive() {
        let result = SVGGeometry.parseAlignment(from: "\"vertical-align: 2.5ex;\"")
        #expect(result == 2.5)
    }

    @Test("parseAlignment handles zero value with ex suffix")
    func parseAlignmentZeroEx() {
        let result = SVGGeometry.parseAlignment(from: "\"vertical-align: 0ex;\"")
        #expect(result == 0)
    }

    // MARK: - parseXHeight

    @Test("parseXHeight handles standard values")
    func parseXHeightStandard() {
        let result = SVGGeometry.parseXHeight(from: "\"3.5ex\"")
        #expect(result == 3.5)
    }

    @Test("parseXHeight returns nil for non-numeric values")
    func parseXHeightNonNumeric() {
        let result = SVGGeometry.parseXHeight(from: "\"abcex\"")
        #expect(result == nil)
    }

    @Test("parseXHeight handles zero")
    func parseXHeightZero() {
        let result = SVGGeometry.parseXHeight(from: "\"0ex\"")
        #expect(result == 0.0)
    }

    @Test("parseXHeight handles negative values")
    func parseXHeightNegative() {
        let result = SVGGeometry.parseXHeight(from: "\"-2.5ex\"")
        #expect(result == -2.5)
    }

    // MARK: - parseViewBox

    @Test("parseViewBox returns nil for less than 4 components")
    func parseViewBoxTooFewComponents() {
        let result = SVGGeometry.parseViewBox(from: "\"0 0 100\"")
        #expect(result == nil)
    }

    @Test("parseViewBox returns nil for non-numeric components")
    func parseViewBoxNonNumeric() {
        let result = SVGGeometry.parseViewBox(from: "\"a b c d\"")
        #expect(result == nil)
    }

    @Test("parseViewBox handles negative y value")
    func parseViewBoxNegativeY() {
        let result = SVGGeometry.parseViewBox(from: "\"0 -500 1000 1500\"")
        #expect(result == CGRect(x: 0, y: -500, width: 1000, height: 1500))
    }

    @Test("parseViewBox handles all zeros")
    func parseViewBoxAllZeros() {
        let result = SVGGeometry.parseViewBox(from: "\"0 0 0 0\"")
        #expect(result == CGRect.zero)
    }

    @Test("parseViewBox handles floating point values")
    func parseViewBoxFloatingPoint() {
        let result = SVGGeometry.parseViewBox(from: "\"1.5 2.5 3.5 4.5\"")
        #expect(result == CGRect(x: 1.5, y: 2.5, width: 3.5, height: 4.5))
    }

    // MARK: - XHeight Conversions

    @Test("XHeight toPoints multiplies by xHeight")
    func xHeightToPoints() {
        let value: SVGGeometry.XHeight = 2.5
        let points = value.toPoints(10.0)
        #expect(points == 25.0)
    }

    @Test("XHeight toPoints with zero xHeight returns zero")
    func xHeightToPointsZero() {
        let value: SVGGeometry.XHeight = 2.5
        let points = value.toPoints(0.0)
        #expect(points == 0.0)
    }

    @Test("XHeight init from string without ex suffix")
    func xHeightInitWithoutSuffix() {
        let value = SVGGeometry.XHeight(stringValue: "3.14")
        #expect(value == 3.14)
    }

    @Test("XHeight init from string with ex suffix")
    func xHeightInitWithSuffix() {
        let value = SVGGeometry.XHeight(stringValue: "3.14ex")
        #expect(value == 3.14)
    }

    @Test("XHeight init returns nil for completely non-numeric string")
    func xHeightInitNonNumeric() {
        let value = SVGGeometry.XHeight(stringValue: "abcdef")
        #expect(value == nil)
    }

    // MARK: - SVGGeometry Parsing Errors

    @Test("SVGGeometry throws missingSVGElement for empty string")
    func geometryThrowsForEmptyString() {
        #expect(throws: SVGGeometry.ParsingError.self) {
            _ = try SVGGeometry(svg: "")
        }
    }

    @Test("SVGGeometry throws missingSVGElement for non-SVG HTML")
    func geometryThrowsForNonSVG() {
        #expect(throws: SVGGeometry.ParsingError.self) {
            _ = try SVGGeometry(svg: "<div>hello</div>")
        }
    }

    @Test("SVGGeometry throws missingGeometry when attributes are absent")
    func geometryThrowsForMissingAttributes() {
        #expect(throws: SVGGeometry.ParsingError.self) {
            _ = try SVGGeometry(svg: "<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>")
        }
    }
}
