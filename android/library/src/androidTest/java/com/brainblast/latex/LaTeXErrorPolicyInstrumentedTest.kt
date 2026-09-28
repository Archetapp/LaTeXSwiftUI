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
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
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
class LaTeXErrorPolicyInstrumentedTest {
    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun rendersFourErrorPoliciesAndRecoversWithoutStaleCallbacks() {
        val completions = mutableStateListOf<String>()
        val errors = mutableStateListOf<String>()
        var recoverySource by mutableStateOf(MalformedSource)

        composeRule.setContent {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.White)
                    .testTag(FixtureTag),
            ) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .widthIn(max = 720.dp)
                        .padding(20.dp),
                ) {
                    ErrorPolicyFixture(
                        label = "Rendered · lenient output",
                        mode = LaTeXErrorMode.Rendered,
                        source = MalformedSource,
                        completions = completions,
                        errors = errors,
                    )
                    ErrorPolicyFixture(
                        label = "Original · authored TeX fallback",
                        mode = LaTeXErrorMode.Original,
                        source = MalformedSource,
                        completions = completions,
                        errors = errors,
                    )
                    ErrorPolicyFixture(
                        label = "Error · MathJax message",
                        mode = LaTeXErrorMode.Error,
                        source = MalformedSource,
                        completions = completions,
                        errors = errors,
                    )
                    ErrorPolicyFixture(
                        label = "Rendered + diagnostic",
                        mode = LaTeXErrorMode.RenderedWithDiagnostic,
                        source = MalformedSource,
                        completions = completions,
                        errors = errors,
                    )
                    ErrorPolicyFixture(
                        label = "Recovery · malformed → valid",
                        mode = LaTeXErrorMode.RenderedWithDiagnostic,
                        source = recoverySource,
                        completions = completions,
                        errors = errors,
                    )
                }
            }
        }

        composeRule.waitUntil(timeoutMillis = 30_000) {
            completions.size == InitialRenderCount
        }
        assertEquals(
            "Expected one reported MathJax error per initial policy: $errors",
            InitialRenderCount,
            errors.size,
        )
        composeRule.runOnIdle {
            recoverySource = ValidSource
        }
        composeRule.waitUntil(timeoutMillis = 20_000) {
            completions.size == RecoveredRenderCount
        }
        composeRule.waitForIdle()

        assertEquals(InitialRenderCount, errors.size)
        assertTrue(errors.all { it.substringAfter(':').isNotBlank() })
        assertEquals(
            1,
            errors.count { it.startsWith("Recovery · malformed → valid:") },
        )

        val image = composeRule.onNodeWithTag(FixtureTag).captureToImage()
        image.asAndroidBitmap().writeToTestStorage(FixtureName)

        assertTrue(image.width > 0)
        assertTrue(image.height > 0)
    }

    @androidx.compose.runtime.Composable
    private fun ErrorPolicyFixture(
        label: String,
        mode: LaTeXErrorMode,
        source: String,
        completions: MutableList<String>,
        errors: MutableList<String>,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
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
                    .padding(10.dp),
                configuration = LaTeXConfiguration(
                    fontSize = 19.sp,
                    foregroundColor = Color(0xFF111111),
                    errorMode = mode,
                ),
                onRenderComplete = {
                    completions += "$label:$source"
                },
                onRenderError = { message ->
                    errors += "$label:$message"
                },
            )
        }
    }

    private companion object {
        const val InitialRenderCount = 5
        const val RecoveredRenderCount = 6
        const val FixtureTag = "latex-error-policy-fixture"
        const val FixtureName = "latex-error-policy-phone-fixture"
        const val MalformedSource = "Value: \$\$\\left( x\$\$"
        const val ValidSource = "Recovered: \$\$x = 2\$\$"
    }
}
