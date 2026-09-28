package com.brainblast.latex

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.test.core.graphics.writeToTestStorage
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class LaTeXAlwaysInlineInstrumentedTest {
    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun rendersBlockComparisonAndWrappedInlineBaselineFixture() {
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
                    verticalArrangement = Arrangement.spacedBy(18.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .widthIn(max = 720.dp)
                        .padding(20.dp),
                ) {
                    FixtureSection(
                        label = "BlockViews · display boundaries",
                        source = ComparisonSource,
                        configuration = fixtureConfiguration(LaTeXBlockMode.BlockViews),
                        onRenderComplete = { completedRenderCount += 1 },
                        onRenderError = errors::add,
                    )
                    FixtureSection(
                        label = "AlwaysInline · flattened boundaries",
                        source = ComparisonSource,
                        configuration = fixtureConfiguration(LaTeXBlockMode.AlwaysInline),
                        onRenderComplete = { completedRenderCount += 1 },
                        onRenderError = errors::add,
                    )
                    FixtureSection(
                        label = "AlwaysInline · wrapped prose baseline",
                        source = WrappedProseSource,
                        configuration = fixtureConfiguration(LaTeXBlockMode.AlwaysInline),
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
        image.asAndroidBitmap().writeToTestStorage(FixtureName)

        assertTrue(image.width > 0)
        assertTrue(image.height > 0)
    }

    @androidx.compose.runtime.Composable
    private fun FixtureSection(
        label: String,
        source: String,
        configuration: LaTeXConfiguration,
        onRenderComplete: () -> Unit,
        onRenderError: (String) -> Unit,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            BasicText(
                text = label,
                style = TextStyle(
                    color = Color(0xFF394150),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                ),
            )
            LaTeX(
                source = source,
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFFF6F8FB), RoundedCornerShape(8.dp))
                    .border(1.dp, Color(0xFFD8DEE8), RoundedCornerShape(8.dp))
                    .padding(12.dp),
                configuration = configuration,
                onRenderComplete = onRenderComplete,
                onRenderError = onRenderError,
            )
        }
    }

    private fun fixtureConfiguration(
        blockMode: LaTeXBlockMode,
    ): LaTeXConfiguration = LaTeXConfiguration(
        fontSize = 21.sp,
        foregroundColor = Color(0xFF111111),
        blockMode = blockMode,
    )

    private companion object {
        const val ExpectedRenderCount = 3
        const val FixtureTag = "latex-always-inline-fixture"
        const val FixtureName = "latex-always-inline-phone-fixture"
        const val ComparisonSource = "Before \n\\[x = 2\\]\n after"
        const val WrappedProseSource =
            "Use \\[x = \\frac{-b}{2a}\\] to find the axis, then verify \$f(x)\$ on both sides."
    }
}
