package com.brainblast.latex

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LaTeXParserTest {
    @Test
    fun parsesInlineDelimiters() {
        val parsed = LaTeXParser.parse("""\(x^2 + 1\)""")

        assertEquals("x^2 + 1", parsed.rawValue)
        assertFalse(parsed.displayMode)
    }

    @Test
    fun parsesDisplayDelimiters() {
        val parsed = LaTeXParser.parse("""\[x^2 + 1\]""")

        assertEquals("x^2 + 1", parsed.rawValue)
        assertTrue(parsed.displayMode)
    }

    @Test
    fun preservesUndelimitedSource() {
        assertEquals(
            LaTeXSource(rawValue = "x^2 + 1", displayMode = false),
            LaTeXParser.parse("x^2 + 1"),
        )
    }

    @Test
    fun parsesMixedTextAndInlineEquation() {
        assertEquals(
            listOf(
                LaTeXComponent("Hello, ", LaTeXComponentType.Text),
                LaTeXComponent("\\TeX", LaTeXComponentType.InlineEquation),
                LaTeXComponent("!", LaTeXComponentType.Text),
            ),
            LaTeXParser.parseComponents("Hello, $\\TeX$!"),
        )
    }

    @Test
    fun parsesDisplayAndNamedEquations() {
        assertEquals(
            LaTeXComponent("x^2", LaTeXComponentType.TexEquation),
            LaTeXParser.parseComponents("\$\$x^2\$\$").single(),
        )
        assertEquals(
            LaTeXComponent("E=mc^2", LaTeXComponentType.NamedEquation),
            LaTeXParser.parseComponents(
                "\\begin{equation}E=mc^2\\end{equation}",
            ).single(),
        )
    }

    @Test
    fun escapedDelimiterRemainsText() {
        val source = "This costs \\$5.00."
        assertEquals(
            listOf(LaTeXComponent(source, LaTeXComponentType.Text)),
            LaTeXParser.parseComponents(source),
        )
    }

    @Test
    fun blockEquationIsSeparatedFromInlineContent() {
        val blocks = LaTeXParser.parseBlocks(
            input = "Before \\[x^2\\] After",
            mode = LaTeXParsingMode.OnlyEquations,
        )

        assertEquals(3, blocks.size)
        assertEquals("Before ", blocks[0].components.single().text)
        assertTrue(blocks[1].isEquationBlock)
        assertEquals(" After", blocks[2].components.single().text)
    }

    @Test
    fun alwaysInlineTrimsOnlyBoundaryNewlinesFromTextComponents() {
        val component = LaTeXComponent(
            text = "\n  Before\nAfter  \n",
            type = LaTeXComponentType.Text,
        )

        assertEquals(
            "  Before\nAfter  ",
            component.textForLayout(LaTeXBlockMode.AlwaysInline),
        )
        assertEquals(
            "\n  Before\nAfter  \n",
            component.textForLayout(LaTeXBlockMode.BlockViews),
        )
    }

    @Test
    fun allModeTreatsEntireInputAsInlineEquation() {
        val blocks = LaTeXParser.parseBlocks(
            input = "x^2 + y^2 = 1",
            mode = LaTeXParsingMode.All,
        )

        assertEquals(1, blocks.size)
        assertEquals(
            LaTeXComponent("x^2 + y^2 = 1", LaTeXComponentType.InlineEquation),
            blocks.single().components.single(),
        )
    }

    @Test
    fun mathJaxDigitScriptWorkaroundMatchesSwift() {
        assertEquals(
            "x^{n+1 }",
            MathJaxInputNormalizer.insertSpaceBeforeDigitScriptBrace("x^{n+1}"),
        )
        assertEquals(
            "x_{12 }",
            MathJaxInputNormalizer.insertSpaceBeforeDigitScriptBrace("x_{12}"),
        )
        assertEquals(
            "\\textcolor{#ff3b30}{x}",
            MathJaxInputNormalizer.insertSpaceBeforeDigitScriptBrace(
                "\\textcolor{#ff3b30}{x}",
            ),
        )
        assertEquals(
            "x^{y^{2 }}",
            MathJaxInputNormalizer.insertSpaceBeforeDigitScriptBrace("x^{y^{2}}"),
        )
    }
}
