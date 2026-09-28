package com.brainblast.latex

data class LaTeXSource(
    val rawValue: String,
    val displayMode: Boolean,
)

object LaTeXParser {
    private val displayDelimiters = listOf(
        "\\[" to "\\]",
        "$$" to "$$",
    )
    private val inlineDelimiters = listOf(
        "\\(" to "\\)",
        "$" to "$",
    )

    fun parse(source: String): LaTeXSource {
        val trimmed = source.trim()

        displayDelimiters.firstNotNullOfOrNull { (opening, closing) ->
            trimmed.unwrap(opening, closing)?.let {
                LaTeXSource(rawValue = it, displayMode = true)
            }
        }?.let { return it }

        inlineDelimiters.firstNotNullOfOrNull { (opening, closing) ->
            trimmed.unwrap(opening, closing)?.let {
                LaTeXSource(rawValue = it, displayMode = false)
            }
        }?.let { return it }

        return LaTeXSource(rawValue = trimmed, displayMode = false)
    }

    fun parseComponents(input: String): List<LaTeXComponent> {
        val components = mutableListOf<LaTeXComponent>()
        val stack = mutableListOf<LaTeXComponentType>()
        var index = 0
        var startIndex = 0
        var endIndex = 0

        inputLoop@ while (index < input.length) {
            if (stack.isNotEmpty()) {
                for (type in LaTeXComponentType.parsingOrder) {
                    val end = type.rightTerminator ?: continue
                    if (!input.startsWith(end, startIndex = index)) continue

                    if (index > 0 && input[index - 1] == '\\') {
                        index += end.length
                        continue@inputLoop
                    }

                    val previousEndIndex = endIndex
                    endIndex = index + end.length

                    if (stack.last() == type) {
                        val lastType = stack.removeAt(stack.lastIndex)
                        if (stack.isEmpty()) {
                            if (previousEndIndex < startIndex) {
                                components += LaTeXComponent(
                                    text = input.substring(previousEndIndex, startIndex),
                                    type = LaTeXComponentType.Text,
                                )
                            }
                            components += LaTeXComponent.fromDelimitedText(
                                text = input.substring(startIndex, endIndex),
                                type = lastType,
                            )
                        }
                    }
                    index = endIndex
                    continue@inputLoop
                }
            }

            for (type in LaTeXComponentType.parsingOrder) {
                val start = type.leftTerminator ?: continue
                if (!input.startsWith(start, startIndex = index)) continue

                if (index > 0 && input[index - 1] == '\\') {
                    index += start.length
                    continue@inputLoop
                }

                if (stack.isEmpty()) startIndex = index
                stack += type
                index += start.length
                continue@inputLoop
            }

            index += 1
        }

        if (endIndex < index) {
            components += LaTeXComponent(
                text = input.substring(endIndex, index),
                type = LaTeXComponentType.Text,
            )
        }

        return components
    }

    fun parseBlocks(
        input: String,
        mode: LaTeXParsingMode,
    ): List<LaTeXComponentBlock> {
        val components = when (mode) {
            LaTeXParsingMode.All -> listOf(
                LaTeXComponent(
                    text = input,
                    type = LaTeXComponentType.InlineEquation,
                ),
            )

            LaTeXParsingMode.OnlyEquations -> parseComponents(input)
        }

        val blocks = mutableListOf<LaTeXComponentBlock>()
        val inlineComponents = mutableListOf<LaTeXComponent>()

        components.forEach { component ->
            if (component.type.inline) {
                inlineComponents += component
            } else {
                blocks += LaTeXComponentBlock(components = inlineComponents.toList())
                blocks += LaTeXComponentBlock(components = listOf(component))
                inlineComponents.clear()
            }
        }

        if (inlineComponents.isNotEmpty()) {
            blocks += LaTeXComponentBlock(components = inlineComponents.toList())
        }

        return blocks
    }

    private fun String.unwrap(opening: String, closing: String): String? {
        if (!startsWith(opening) || !endsWith(closing) || length < opening.length + closing.length) {
            return null
        }
        return substring(opening.length, length - closing.length).trim()
    }
}

object MathJaxInputNormalizer {
    fun insertSpaceBeforeDigitScriptBrace(text: String): String {
        val result = StringBuilder(text.length + 4)
        val braceIsScript = mutableListOf<Boolean>()
        var lastSignificant: Char? = null
        var index = 0

        while (index < text.length) {
            val char = text[index]
            val next = index + 1

            if (char == '\\') {
                result.append(char)
                if (next < text.length) {
                    result.append(text[next])
                    lastSignificant = text[next]
                    index = next + 1
                } else {
                    index = next
                }
                continue
            }

            if (char == '{') {
                braceIsScript += lastSignificant == '^' || lastSignificant == '_'
                result.append(char)
                lastSignificant = char
                index = next
                continue
            }

            if (char == '}') {
                val isScript =
                    if (braceIsScript.isEmpty()) false else braceIsScript.removeAt(braceIsScript.lastIndex)
                if (isScript && lastSignificant?.isDigit() == true) result.append(' ')
                result.append(char)
                lastSignificant = char
                index = next
                continue
            }

            result.append(char)
            if (!char.isWhitespace()) lastSignificant = char
            index = next
        }

        return result.toString()
    }
}
