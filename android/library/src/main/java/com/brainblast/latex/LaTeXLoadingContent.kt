package com.brainblast.latex

import android.animation.ValueAnimator
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp

@Composable
internal fun LaTeXLoadingContent(
    source: String,
    renderingStyle: LaTeXRenderingStyle,
    fontSize: TextUnit,
    foregroundColor: Color,
    modifier: Modifier = Modifier,
) {
    val resolvedColor = foregroundColor.takeUnless { it == Color.Unspecified } ?: DefaultInk
    val textStyle = TextStyle(
        color = resolvedColor,
        fontSize = fontSize,
    )

    when (renderingStyle) {
        LaTeXRenderingStyle.Empty -> Spacer(modifier)
        LaTeXRenderingStyle.Original,
        LaTeXRenderingStyle.Wait,
        -> BasicText(
            text = source,
            modifier = modifier,
            style = textStyle,
        )
        LaTeXRenderingStyle.RedactedOriginal -> BasicText(
            text = source,
            modifier = modifier.drawBehind {
                drawRoundRect(
                    color = resolvedColor.copy(alpha = RedactedAlpha),
                    cornerRadius = CornerRadius(RedactedCornerRadius.toPx()),
                )
            },
            style = textStyle.copy(color = Color.Transparent),
        )
        LaTeXRenderingStyle.Progress -> LaTeXProgressIndicator(
            color = resolvedColor,
            modifier = modifier,
        )
    }
}

@Composable
private fun LaTeXProgressIndicator(
    color: Color,
    modifier: Modifier,
) {
    val rotation = if (ValueAnimator.areAnimatorsEnabled()) {
        val transition = rememberInfiniteTransition(label = "LaTeX rendering")
        transition.animateFloat(
            initialValue = 0f,
            targetValue = 360f,
            animationSpec = infiniteRepeatable(
                animation = tween(
                    durationMillis = ProgressRotationDurationMillis,
                    easing = LinearEasing,
                ),
                repeatMode = RepeatMode.Restart,
            ),
            label = "LaTeX rendering rotation",
        ).value
    } else {
        0f
    }

    Canvas(
        modifier = modifier
            .size(ProgressSize)
            .semantics {
                contentDescription = "Rendering equation"
            },
    ) {
        rotate(rotation) {
            drawArc(
                color = color,
                startAngle = ProgressStartAngle,
                sweepAngle = ProgressSweepAngle,
                useCenter = false,
                style = Stroke(
                    width = ProgressStrokeWidth.toPx(),
                    cap = StrokeCap.Round,
                ),
            )
        }
    }
}

private val DefaultInk = Color(0xFF111111)
private val ProgressSize = 20.dp
private val ProgressStrokeWidth = 2.dp
private val RedactedCornerRadius = 3.dp
private const val RedactedAlpha = 0.2f
private const val ProgressRotationDurationMillis = 900
private const val ProgressStartAngle = -90f
private const val ProgressSweepAngle = 250f
