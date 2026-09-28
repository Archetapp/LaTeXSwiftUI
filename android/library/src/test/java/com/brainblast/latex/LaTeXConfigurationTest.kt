package com.brainblast.latex

import org.junit.Assert.assertEquals
import org.junit.Test

class LaTeXConfigurationTest {
    @Test
    fun blockViewsRemainTheDefaultBlockMode() {
        assertEquals(
            LaTeXBlockMode.BlockViews,
            LaTeXConfiguration().blockMode,
        )
    }

    @Test
    fun originalTextRemainsTheDefaultErrorMode() {
        assertEquals(
            LaTeXErrorMode.Original,
            LaTeXConfiguration().errorMode,
        )
    }

    @Test
    fun originalTextRemainsTheDefaultRenderingStyle() {
        assertEquals(
            LaTeXRenderingStyle.Original,
            LaTeXDefaults.renderingStyle,
        )
    }

    @Test
    fun renderingStylesMatchTheFiveSourcePolicies() {
        assertEquals(
            listOf(
                LaTeXRenderingStyle.Empty,
                LaTeXRenderingStyle.Original,
                LaTeXRenderingStyle.RedactedOriginal,
                LaTeXRenderingStyle.Progress,
                LaTeXRenderingStyle.Wait,
            ),
            LaTeXRenderingStyle.entries,
        )
    }

    @Test
    fun templateRemainsTheDefaultImageRenderingMode() {
        assertEquals(
            LaTeXImageRenderingMode.Template,
            LaTeXDefaults.imageRenderingMode,
        )
        assertEquals(LaTeXDefaults.imageRenderingMode, LaTeXConfiguration().imageRenderingMode)
    }

    @Test
    fun colorCommandsPromoteTemplateRenderingToOriginal() {
        listOf(
            "\\color{red}{x}",
            "\\textcolor{blue}{x}",
            "\\textcolor[RGB]{37,99,235}{x}",
        ).forEach { source ->
            assertEquals(
                LaTeXImageRenderingMode.Original,
                LaTeXImageRenderingMode.Template.resolvedFor(source),
            )
        }
        assertEquals(
            LaTeXImageRenderingMode.Template,
            LaTeXImageRenderingMode.Template.resolvedFor("x^2 + y^2"),
        )
    }

    @Test
    fun errorModesMatchTheFourSourcePolicies() {
        assertEquals(
            listOf(
                LaTeXErrorMode.Rendered,
                LaTeXErrorMode.Original,
                LaTeXErrorMode.Error,
                LaTeXErrorMode.RenderedWithDiagnostic,
            ),
            LaTeXErrorMode.entries,
        )
    }
}
