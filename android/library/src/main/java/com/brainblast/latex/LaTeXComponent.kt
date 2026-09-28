package com.brainblast.latex

enum class LaTeXComponentType(
    val leftTerminator: String?,
    val rightTerminator: String?,
    val inline: Boolean,
) {
    Text(null, null, true),
    InlineEquation("$", "$", true),
    InlineParenthesesEquation("\\(", "\\)", true),
    TexEquation("$$", "$$", false),
    BlockEquation("\\[", "\\]", false),
    NamedEquation("\\begin{equation}", "\\end{equation}", false),
    NamedNoNumberEquation("\\begin{equation*}", "\\end{equation*}", false);

    companion object {
        val parsingOrder = listOf(
            NamedNoNumberEquation,
            NamedEquation,
            BlockEquation,
            TexEquation,
            InlineEquation,
            InlineParenthesesEquation,
        )
    }
}

data class LaTeXComponent(
    val text: String,
    val type: LaTeXComponentType,
) {
    val originalText: String
        get() = "${type.leftTerminator.orEmpty()}$text${type.rightTerminator.orEmpty()}"

    val isEquation: Boolean
        get() = type != LaTeXComponentType.Text

    internal fun textForLayout(blockMode: LaTeXBlockMode): String =
        if (blockMode == LaTeXBlockMode.AlwaysInline) {
            text.trim('\n')
        } else {
            text
        }

    companion object {
        fun fromDelimitedText(
            text: String,
            type: LaTeXComponentType,
        ): LaTeXComponent {
            if (type == LaTeXComponentType.Text) {
                return LaTeXComponent(text = text, type = type)
            }

            var innerText = text
            type.leftTerminator?.let { left ->
                if (innerText.startsWith(left)) innerText = innerText.removePrefix(left)
            }
            type.rightTerminator?.let { right ->
                if (innerText.endsWith(right)) innerText = innerText.removeSuffix(right)
            }
            return LaTeXComponent(text = innerText, type = type)
        }
    }
}

data class LaTeXComponentBlock(
    val components: List<LaTeXComponent>,
) {
    val isEquationBlock: Boolean
        get() = components.size == 1 && !components.first().type.inline
}

enum class LaTeXParsingMode {
    All,
    OnlyEquations,
}
