package com.brainblast.latex

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LaTeXDisplayEquationLayoutTest {
    @Test
    fun keepsSmallEquationAtIntrinsicSize() {
        val layout = LaTeXDisplayEquationLayoutResolver.resolve(
            intrinsicWidth = 180f,
            intrinsicHeight = 40f,
            availableWidth = 320f,
        )

        assertEquals(1f, layout.scaleFactor)
        assertEquals(180f, layout.renderedWidth)
        assertFalse(layout.requiresHorizontalScrolling)
    }

    @Test
    fun choosesFirstDiscreteScaleThatFits() {
        val ninetyPercent = LaTeXDisplayEquationLayoutResolver.resolve(
            intrinsicWidth = 400f,
            intrinsicHeight = 80f,
            availableWidth = 360f,
        )
        val seventyPercent = LaTeXDisplayEquationLayoutResolver.resolve(
            intrinsicWidth = 500f,
            intrinsicHeight = 100f,
            availableWidth = 360f,
        )

        assertEquals(0.9f, ninetyPercent.scaleFactor)
        assertEquals(0.7f, seventyPercent.scaleFactor)
        assertFalse(ninetyPercent.requiresHorizontalScrolling)
        assertFalse(seventyPercent.requiresHorizontalScrolling)
    }

    @Test
    fun scrollsOnlyAfterConfiguredMinimumCannotFit() {
        val layout = LaTeXDisplayEquationLayoutResolver.resolve(
            intrinsicWidth = 1_000f,
            intrinsicHeight = 100f,
            availableWidth = 320f,
        )

        assertEquals(0.65f, layout.scaleFactor)
        assertEquals(650f, layout.renderedWidth)
        assertEquals(320f, layout.visibleFrameWidth)
        assertTrue(layout.requiresHorizontalScrolling)
    }

    @Test
    fun neverChoosesScaleBelowConfiguredMinimum() {
        val layout = LaTeXDisplayEquationLayoutResolver.resolve(
            intrinsicWidth = 500f,
            intrinsicHeight = 100f,
            availableWidth = 380f,
            minimumScale = 0.8f,
        )

        assertEquals(0.8f, layout.scaleFactor)
        assertTrue(layout.requiresHorizontalScrolling)
    }

    @Test
    fun invalidIntrinsicSizeProducesSafeEmptyLayout() {
        val layout = LaTeXDisplayEquationLayoutResolver.resolve(
            intrinsicWidth = Float.NaN,
            intrinsicHeight = 40f,
            availableWidth = 320f,
        )

        assertEquals(0f, layout.renderedWidth)
        assertEquals(320f, layout.visibleFrameWidth)
        assertFalse(layout.requiresHorizontalScrolling)
    }
}
