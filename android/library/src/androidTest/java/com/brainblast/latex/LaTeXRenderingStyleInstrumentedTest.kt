package com.brainblast.latex

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.test.core.graphics.writeToTestStorage
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class LaTeXRenderingStyleInstrumentedTest {
    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun activeLoadingStylesAndImageModesWriteNamedFixture() {
        val completions = mutableStateListOf<String>()

        composeRule.setContent {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.White)
                    .testTag(FixtureTag),
            ) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .widthIn(max = 720.dp)
                        .padding(20.dp),
                ) {
                    FixtureHeading("ACTIVE LOADING STYLES")
                    LoadingStyleCard(
                        label = "EMPTY · no source flash",
                        source = EmptyLoadingSource,
                        style = LaTeXRenderingStyle.Empty,
                    )
                    LoadingStyleCard(
                        label = "ORIGINAL · authored source",
                        source = OriginalLoadingSource,
                        style = LaTeXRenderingStyle.Original,
                    )

                    FixtureHeading("IMAGE RENDERING MODES")
                    RenderedEquationCard(
                        label = "TEMPLATE · theme tint",
                        source = TemplateSource,
                        tag = TemplateTag,
                        configuration = LaTeXConfiguration(
                            fontSize = 24.sp,
                            foregroundColor = TemplateBlue,
                            imageRenderingMode = LaTeXImageRenderingMode.Template,
                        ),
                        renderingStyle = LaTeXRenderingStyle.Empty,
                        completions = completions,
                    )
                    RenderedEquationCard(
                        label = "ORIGINAL · authored colors",
                        source = OriginalColorSource,
                        tag = OriginalTag,
                        configuration = LaTeXConfiguration(
                            fontSize = 24.sp,
                            foregroundColor = BaseInk,
                            imageRenderingMode = LaTeXImageRenderingMode.Original,
                        ),
                        renderingStyle = LaTeXRenderingStyle.Original,
                        completions = completions,
                    )
                    RenderedEquationCard(
                        label = "TEMPLATE → ORIGINAL · color command",
                        source = AutomaticColorSource,
                        tag = AutomaticTag,
                        configuration = LaTeXConfiguration(
                            fontSize = 24.sp,
                            foregroundColor = BaseInk,
                            imageRenderingMode = LaTeXImageRenderingMode.Template,
                        ),
                        renderingStyle = LaTeXRenderingStyle.Empty,
                        completions = completions,
                    )
                }
            }
        }

        composeRule.onAllNodesWithText(EmptyLoadingSource).assertCountEquals(0)
        composeRule.onAllNodesWithText(OriginalLoadingSource).assertCountEquals(1)
        composeRule.waitUntil(timeoutMillis = 30_000) {
            completions.size == RenderedEquationCount
        }
        composeRule.waitForIdle()

        val templateImage = composeRule.onNodeWithTag(TemplateTag).captureToImage()
        val originalImage = composeRule.onNodeWithTag(OriginalTag).captureToImage()
        val automaticImage = composeRule.onNodeWithTag(AutomaticTag).captureToImage()

        assertTrue(templateImage.countPixels(::isBluePixel) > MinimumColoredPixels)
        assertTrue(templateImage.countPixels(::isRedPixel) == 0)
        assertTrue(originalImage.countPixels(::isRedPixel) > MinimumColoredPixels)
        assertTrue(originalImage.countPixels(::isBluePixel) > MinimumColoredPixels)
        assertTrue(automaticImage.countPixels(::isGreenPixel) > MinimumColoredPixels)
        assertTrue(automaticImage.countPixels(::isPurplePixel) > MinimumColoredPixels)

        val fixture = composeRule.onNodeWithTag(FixtureTag).captureToImage()
        fixture.asAndroidBitmap().writeToTestStorage(FixtureName)
        assertTrue(fixture.width > 0)
        assertTrue(fixture.height > 0)
    }

    @androidx.compose.runtime.Composable
    private fun FixtureHeading(text: String) {
        BasicText(
            text = text,
            style = TextStyle(
                color = Color(0xFF394150),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.8.sp,
            ),
        )
    }

    @androidx.compose.runtime.Composable
    private fun LoadingStyleCard(
        label: String,
        source: String,
        style: LaTeXRenderingStyle,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
            FixtureLabel(label)
            Box(
                contentAlignment = Alignment.CenterStart,
                modifier = FixtureCardModifier.height(48.dp),
            ) {
                LaTeXLoadingContent(
                    source = source,
                    renderingStyle = style,
                    fontSize = 17.sp,
                    foregroundColor = BaseInk,
                )
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun RenderedEquationCard(
        label: String,
        source: String,
        tag: String,
        configuration: LaTeXConfiguration,
        renderingStyle: LaTeXRenderingStyle,
        completions: MutableList<String>,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
            FixtureLabel(label)
            LaTeX(
                source = source,
                modifier = FixtureCardModifier.testTag(tag),
                configuration = configuration,
                renderingStyle = renderingStyle,
                onRenderComplete = {
                    completions += tag
                },
            )
        }
    }

    @androidx.compose.runtime.Composable
    private fun FixtureLabel(text: String) {
        BasicText(
            text = text,
            style = TextStyle(
                color = Color(0xFF596273),
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
            ),
        )
    }

    private fun androidx.compose.ui.graphics.ImageBitmap.countPixels(
        predicate: (Color) -> Boolean,
    ): Int {
        val pixels = toPixelMap()
        var count = 0
        for (y in 0 until pixels.height) {
            for (x in 0 until pixels.width) {
                if (predicate(pixels[x, y])) count += 1
            }
        }
        return count
    }

    private fun isRedPixel(color: Color): Boolean =
        color.red > 0.62f && color.red > color.green * 1.8f && color.red > color.blue * 1.8f

    private fun isBluePixel(color: Color): Boolean =
        color.blue > 0.62f && color.blue > color.red * 1.8f && color.blue > color.green * 1.35f

    private fun isGreenPixel(color: Color): Boolean =
        color.green > 0.48f && color.green > color.red * 1.45f && color.green > color.blue * 1.25f

    private fun isPurplePixel(color: Color): Boolean =
        color.red > 0.4f && color.blue > 0.58f && color.blue > color.green * 1.45f

    private companion object {
        val FixtureCardModifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFFF6F8FB), RoundedCornerShape(8.dp))
            .border(1.dp, Color(0xFFD8DEE8), RoundedCornerShape(8.dp))
            .padding(horizontal = 12.dp, vertical = 8.dp)

        val BaseInk = Color(0xFF374151)
        val TemplateBlue = Color(0xFF2563EB)

        const val RenderedEquationCount = 3
        const val MinimumColoredPixels = 12
        const val FixtureTag = "latex-rendering-style-fixture"
        const val FixtureName = "latex-rendering-style-phone-fixture"
        const val TemplateTag = "latex-template-equation"
        const val OriginalTag = "latex-original-equation"
        const val AutomaticTag = "latex-automatic-color-equation"
        const val EmptyLoadingSource = "This source must stay hidden while rendering."
        const val OriginalLoadingSource = "Authored source: \$x^2 + y^2 = r^2\$"
        const val TemplateSource = "\$x^2 + y^2 = r^2\$"
        const val OriginalColorSource =
            "\$\\textcolor[RGB]{219,41,41}{x^2} + \\textcolor[RGB]{37,99,235}{y^2} = r^2\$"
        const val AutomaticColorSource =
            "\$\\textcolor[RGB]{22,163,74}{a} + \\textcolor[RGB]{147,51,234}{b}\$"
    }
}
