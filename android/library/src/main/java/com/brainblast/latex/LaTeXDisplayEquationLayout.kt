package com.brainblast.latex

import kotlin.math.min

data class LaTeXDisplayEquationLayout(
    val scaleFactor: Float,
    val renderedWidth: Float,
    val renderedHeight: Float,
    val visibleFrameWidth: Float,
    val requiresHorizontalScrolling: Boolean,
)

/**
 * Mirrors the active iOS display-equation fitting order:
 * unscaled, 90%, 80%, 70%, the configured minimum, then horizontal scrolling
 * at that minimum.
 */
object LaTeXDisplayEquationLayoutResolver {
    const val DefaultMinimumScale = 0.65f
    const val WidthTolerance = 0.5f

    fun candidateScales(minimumScale: Float): List<Float> {
        val resolvedMinimum = minimumScale.coerceIn(0.01f, 1f)
        return (listOf(1f, 0.9f, 0.8f, 0.7f).filter { it >= resolvedMinimum } + resolvedMinimum)
            .distinct()
    }

    fun resolve(
        intrinsicWidth: Float,
        intrinsicHeight: Float,
        availableWidth: Float,
        minimumScale: Float = DefaultMinimumScale,
    ): LaTeXDisplayEquationLayout {
        if (
            !intrinsicWidth.isFinite() ||
            !intrinsicHeight.isFinite() ||
            intrinsicWidth <= 0f ||
            intrinsicHeight <= 0f
        ) {
            return LaTeXDisplayEquationLayout(
                scaleFactor = 1f,
                renderedWidth = 0f,
                renderedHeight = 0f,
                visibleFrameWidth = if (availableWidth.isFinite()) {
                    availableWidth.coerceAtLeast(0f)
                } else {
                    0f
                },
                requiresHorizontalScrolling = false,
            )
        }
        if (!availableWidth.isFinite() || availableWidth <= 0f) {
            return LaTeXDisplayEquationLayout(
                scaleFactor = 1f,
                renderedWidth = intrinsicWidth,
                renderedHeight = intrinsicHeight,
                visibleFrameWidth = intrinsicWidth,
                requiresHorizontalScrolling = false,
            )
        }

        val resolvedMinimum = minimumScale.coerceIn(0.01f, 1f)
        val scale = candidateScales(resolvedMinimum)
            .firstOrNull {
                intrinsicWidth * it <= availableWidth + WidthTolerance
            }
            ?: resolvedMinimum
        val renderedWidth = intrinsicWidth * scale
        val renderedHeight = intrinsicHeight * scale
        return LaTeXDisplayEquationLayout(
            scaleFactor = scale,
            renderedWidth = renderedWidth,
            renderedHeight = renderedHeight,
            visibleFrameWidth = min(renderedWidth, availableWidth),
            requiresHorizontalScrolling =
                renderedWidth > availableWidth + WidthTolerance,
        )
    }
}
