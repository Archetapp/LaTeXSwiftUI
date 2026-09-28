import Foundation

internal extension Component {
    /// A source-based equation label that identifies script ell as a letter.
    ///
    /// MathJax owns the visual command and glyph. Only the spoken label is
    /// changed here; other TeX commands and ordinary `l` characters are preserved.
    var ellAccessibilityLabel: String? {
        guard type.isEquation else { return nil }
        let characters = Array(text)
        var index = 0
        var label = ""
        var containsEll = false

        while index < characters.count {
            let character = characters[index]
            if character == "\\" {
                let start = index
                index += 1
                let commandStart = index
                while index < characters.count, characters[index].isASCII, characters[index].isLetter {
                    index += 1
                }
                if String(characters[commandStart..<index]) == "ell" {
                    label += " letter ell "
                    containsEll = true
                } else {
                    if index == commandStart, index < characters.count {
                        index += 1
                    }
                    label += String(characters[start..<index])
                }
            } else {
                label += character == "ℓ" ? " letter ell " : String(character)
                containsEll = containsEll || character == "ℓ"
                index += 1
            }
        }

        guard containsEll else { return nil }
        return label.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
