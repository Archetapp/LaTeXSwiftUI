package com.brainblast.latex

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.test.core.graphics.writeToTestStorage
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class LaTeXDisplayLayoutInstrumentedTest {
    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun rendersNamedAlignmentAndWidthFittingFixture() {
        var completedRenderCount by mutableIntStateOf(0)
        val errors = mutableStateListOf<String>()

        composeRule.setContent {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.White)
                    .testTag(FixtureTag),
            ) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .widthIn(max = 720.dp)
                        .padding(16.dp),
                ) {
                    BasicText("Leading · intrinsic", style = FixtureLabelStyle)
                    LaTeX(
                        source = "\\[x^2 + y^2 = r^2\\]",
                        modifier = Modifier.fillMaxWidth(),
                        configuration =
                            fixtureConfiguration(LaTeXBlockAlignment.Leading),
                        onRenderComplete = { completedRenderCount += 1 },
                        onRenderError = errors::add,
                    )

                    Spacer(Modifier.height(2.dp))
                    BasicText("Center · adaptive fit", style = FixtureLabelStyle)
                    LaTeX(
                        source = """
                            \[
                            \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
                            + \int_0^\infty e^{-x^2}\,dx
                            + \sum_{n=1}^{12}\frac{1}{n^2}
                            \]
                        """.trimIndent(),
                        modifier = Modifier.fillMaxWidth(),
                        configuration =
                            fixtureConfiguration(LaTeXBlockAlignment.Center),
                        onRenderComplete = { completedRenderCount += 1 },
                        onRenderError = errors::add,
                    )

                    Spacer(Modifier.height(2.dp))
                    BasicText("Trailing · multiline source", style = FixtureLabelStyle)
                    LaTeX(
                        source = """
                            \[
                            \begin{aligned}
                            a + b &= c \\
                            c - b &= a
                            \end{aligned}
                            \]
                        """.trimIndent(),
                        modifier = Modifier.fillMaxWidth(),
                        configuration =
                            fixtureConfiguration(LaTeXBlockAlignment.Trailing),
                        onRenderComplete = { completedRenderCount += 1 },
                        onRenderError = errors::add,
                    )
                }
            }
        }

        composeRule.waitUntil(timeoutMillis = 20_000) {
            completedRenderCount == ExpectedRenderCount || errors.isNotEmpty()
        }
        composeRule.waitForIdle()

        assertEquals(emptyList<String>(), errors.toList())
        assertEquals(ExpectedRenderCount, completedRenderCount)

        val image = composeRule.onNodeWithTag(FixtureTag).captureToImage()
        val isTablet = InstrumentationRegistry.getInstrumentation()
            .targetContext
            .resources
            .configuration
            .smallestScreenWidthDp >= 700
        image.asAndroidBitmap().writeToTestStorage(
            if (isTablet) TabletFixtureName else PhoneFixtureName,
        )

        assertTrue(image.width > 0)
        assertTrue(image.height > 0)
    }

    private fun fixtureConfiguration(
        alignment: LaTeXBlockAlignment,
    ): LaTeXConfiguration = LaTeXConfiguration(
        fontSize = 22.sp,
        foregroundColor = Color(0xFF111111),
        blockAlignment = alignment,
    )

    private companion object {
        const val ExpectedRenderCount = 3
        const val FixtureTag = "latex-display-layout-fixture"
        const val PhoneFixtureName = "latex-display-layout-phone-fixture"
        const val TabletFixtureName = "latex-display-layout-tablet-fixture"
        val FixtureLabelStyle = TextStyle(fontSize = 13.sp)
    }
}
