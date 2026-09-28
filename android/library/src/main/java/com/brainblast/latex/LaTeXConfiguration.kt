package com.brainblast.latex

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

enum class LaTeXBlockAlignment {
    Leading,
    Center,
    Trailing,
    ;

    internal val cssTextAlign: String
        get() = when (this) {
            Leading -> "left"
            Center -> "center"
            Trailing -> "right"
        }
}

enum class LaTeXBlockMode {
    AlwaysInline,
    BlockViews,
}

enum class LaTeXRenderingStyle {
    Empty,
    Original,
    RedactedOriginal,
    Progress,
    Wait,
}

enum class LaTeXImageRenderingMode {
    Template,
    Original,
    ;

    internal fun resolvedFor(source: String): LaTeXImageRenderingMode {
        if (this == Original) return Original
        val normalizedSource = source.lowercase()
        return if (
            normalizedSource.contains("\\color{") ||
            normalizedSource.contains("\\textcolor{") ||
            normalizedSource.contains("\\textcolor[")
        ) {
            Original
        } else {
            Template
        }
    }
}

object LaTeXDefaults {
    val renderingStyle = LaTeXRenderingStyle.Original
    val imageRenderingMode = LaTeXImageRenderingMode.Template
}

enum class LaTeXErrorMode {
    Rendered,
    Original,
    Error,
    RenderedWithDiagnostic,
    ;

    internal val keepsLenientMathJaxPackages: Boolean
        get() = this == Rendered || this == RenderedWithDiagnostic

    internal val javascriptName: String
        get() = when (this) {
            Rendered -> "rendered"
            Original -> "original"
            Error -> "error"
            RenderedWithDiagnostic -> "renderedWithDiagnostic"
        }
}

data class LaTeXConfiguration(
    val fontSize: TextUnit = 17.sp,
    val foregroundColor: Color = Color.Unspecified,
    val displayMode: Boolean = false,
    val blockMode: LaTeXBlockMode = LaTeXBlockMode.BlockViews,
    val blockAlignment: LaTeXBlockAlignment = LaTeXBlockAlignment.Leading,
    val errorMode: LaTeXErrorMode = LaTeXErrorMode.Original,
    val imageRenderingMode: LaTeXImageRenderingMode = LaTeXDefaults.imageRenderingMode,
    val minimumDisplayScale: Float = 0.65f,
) {
    init {
        require(minimumDisplayScale in 0.01f..1f) {
            "The minimum display-equation scale must be between 0.01 and 1."
        }
    }
}
