package com.brainblast.latex

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MathJaxHtmlDocumentTest {
    @Test
    fun templateAndOriginalImageRenderingModesReachTheDocument() {
        val template = MathJaxHtmlDocument.create(
            source = "\$x\$",
            configuration = LaTeXConfiguration(
                imageRenderingMode = LaTeXImageRenderingMode.Template,
            ),
        )
        val original = MathJaxHtmlDocument.create(
            source = "\$\\textcolor[RGB]{219,41,41}{x}\$",
            configuration = LaTeXConfiguration(
                imageRenderingMode = LaTeXImageRenderingMode.Template,
            ),
        )

        assertTrue(template.contains("class=\"block-views image-template\""))
        assertTrue(template.contains("data-image-rendering-mode=\"template\""))
        assertTrue(original.contains("class=\"block-views image-original\""))
        assertTrue(original.contains("data-image-rendering-mode=\"original\""))
    }

    @Test
    fun usesBundledMathJaxAndNeverReferencesNetworkResources() {
        val html = MathJaxHtmlDocument.create("Solve \$x^2 = 4\$.")

        assertTrue(html.contains("src=\"tex-svg-full.js\""))
        assertTrue(html.contains("svg: { fontCache: 'local' }"))
        assertFalse(html.contains("https://"))
        assertFalse(html.contains("http://"))
    }

    @Test
    fun convertsMixedTextAndEquationsToSafeMathJaxMarkup() {
        val html = MathJaxHtmlDocument.create("If a < b, then \$a^2 < b^2\$.")

        assertTrue(html.contains("If a &lt; b, then "))
        assertTrue(html.contains("\\(a^2 &lt; b^2\\)"))
    }

    @Test
    fun preservesDisplayEquationSemantics() {
        val html = MathJaxHtmlDocument.create("Before\n\\[x = 2\\]\nAfter")

        assertTrue(
            html.contains(
                "<div class=\"display-equation\">" +
                    "<span class=\"math-fragment\" data-original=\"\\[x = 2\\]\">" +
                    "\\[x = 2\\]</span></div>",
            ),
        )
        assertTrue(html.contains("class=\"block-views image-template\""))
    }

    @Test
    fun alwaysInlineFlattensBlocksWithoutChangingDisplayMathStyle() {
        val html = MathJaxHtmlDocument.create(
            source = "\nBefore \n\\[\nx = 2\n\\]\n after\n",
            configuration = LaTeXConfiguration(
                blockMode = LaTeXBlockMode.AlwaysInline,
            ),
        )

        assertTrue(html.contains("class=\"always-inline image-template\""))
        assertTrue(html.contains("data-image-rendering-mode=\"template\""))
        assertTrue(html.contains(">Before <span class=\"math-fragment\""))
        assertTrue(html.contains("\\[\nx = 2\n\\]</span> after</main>"))
        assertFalse(html.contains("<div class=\"display-equation\">"))
        assertTrue(html.contains("#math-content.always-inline mjx-container[display=\"true\"]"))
        assertTrue(html.contains("margin: 0 0.08em"))
        assertFalse(html.contains("Before <br>"))
    }

    @Test
    fun appliesComposeConfigurationToDocumentStyles() {
        val html = MathJaxHtmlDocument.create(
            source = "\$x\$",
            configuration = LaTeXConfiguration(
                fontSize = 24.sp,
                foregroundColor = Color(0xFF123456),
            ),
        )

        assertTrue(html.contains("font-size: 24.0px"))
        assertTrue(html.contains("rgba(18,52,86,1.0)"))
    }

    @Test
    fun normalizesNumericScriptBracesBeforeRendering() {
        val html = MathJaxHtmlDocument.create("\$x^{23}\$")

        assertTrue(html.contains("\\(x^{23 }\\)"))
    }

    @Test
    fun configuresDisplayAlignmentAndIosScaleBeforeScrollOrder() {
        val html = MathJaxHtmlDocument.create(
            source = "\$\$x^2\$\$",
            configuration = LaTeXConfiguration(
                blockAlignment = LaTeXBlockAlignment.Trailing,
                minimumDisplayScale = 0.65f,
            ),
        )

        assertTrue(html.contains("text-align: right"))
        assertTrue(html.contains("padding: 0 0.16em"))
        assertTrue(html.contains("wrapper.clientWidth - horizontalInset"))
        assertTrue(html.contains("const displayScaleCandidates = [1.0,0.9,0.8,0.7,0.65]"))
        assertTrue(html.contains("requiresScrolling ? 'left' : displayAlignment"))
        assertTrue(html.contains("layoutDisplayEquations(true)"))
    }

    @Test
    fun originalAndErrorModesUseStrictMathJaxPackagesAndPerFragmentFallbacks() {
        listOf(LaTeXErrorMode.Original, LaTeXErrorMode.Error).forEach { mode ->
            val html = MathJaxHtmlDocument.create(
                source = "Before \$\\unknown{x}\$ after",
                configuration = LaTeXConfiguration(errorMode = mode),
            )

            assertFalse(html.contains("'[tex]/noerrors'"))
            assertFalse(html.contains("'noundefined'"))
            assertTrue(html.contains("data-original=\"\$\\unknown{x}\$\""))
            assertTrue(html.contains("errorMode = '${mode.javascriptName}'"))
            assertTrue(html.contains("showFallback(fragment, message)"))
            assertTrue(html.contains("errorMode === 'error'"))
        }
    }

    @Test
    fun renderedModesKeepLenientPackagesAndDiagnosticIsOptIn() {
        val rendered = MathJaxHtmlDocument.create(
            source = "\$\$\\frac{1}{\$\$",
            configuration = LaTeXConfiguration(errorMode = LaTeXErrorMode.Rendered),
        )
        val diagnostic = MathJaxHtmlDocument.create(
            source = "\$\$\\frac{1}{\$\$",
            configuration = LaTeXConfiguration(
                errorMode = LaTeXErrorMode.RenderedWithDiagnostic,
            ),
            renderIdentifier = "diagnostic-7",
        )

        listOf(rendered, diagnostic).forEach { html ->
            assertTrue(html.contains("'[tex]/noerrors'"))
            assertTrue(html.contains("'[tex]/noundefined'"))
            assertTrue(html.contains("'noerrors'"))
            assertTrue(html.contains("'noundefined'"))
            assertTrue(html.contains("[data-mjx-error]"))
        }
        assertTrue(rendered.contains("errorMode = 'rendered'"))
        assertTrue(diagnostic.contains("errorMode = 'renderedWithDiagnostic'"))
        assertTrue(diagnostic.contains("diagnostic.style.display = 'block'"))
        assertTrue(diagnostic.contains("const renderIdentifier = 'diagnostic-7'"))
        assertTrue(diagnostic.contains("window.BrainblastMathJax.onError("))
        assertTrue(diagnostic.contains("renderIdentifier,"))
        assertTrue(diagnostic.contains("combinedMessage"))
    }

    @Test
    fun renderCallbacksCarryDocumentIdentityToRejectStaleWebViewResults() {
        val html = MathJaxHtmlDocument.create(
            source = "\$x\$",
            renderIdentifier = "render-42",
        )

        assertTrue(html.contains("const renderIdentifier = 'render-42'"))
        assertTrue(html.contains("onHeight(renderIdentifier, height)"))
        assertTrue(html.contains("onReady(renderIdentifier)"))
        assertTrue(html.contains("window.BrainblastMathJax.onError("))
        assertTrue(html.contains("renderIdentifier,"))
        assertTrue(html.contains("combinedMessage"))
    }
}
