package com.brainblast.latex

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb

object MathJaxHtmlDocument {
    fun create(
        source: String,
        configuration: LaTeXConfiguration = LaTeXConfiguration(),
        parsingMode: LaTeXParsingMode = LaTeXParsingMode.OnlyEquations,
        renderIdentifier: String = "static",
    ): String {
        val blocks = LaTeXParser.parseBlocks(source, parsingMode)
        val alwaysInline = configuration.blockMode == LaTeXBlockMode.AlwaysInline
        val content = buildString {
            blocks.forEach { block ->
                val wrapsDisplayEquation = block.isEquationBlock && !alwaysInline
                if (wrapsDisplayEquation) append("<div class=\"display-equation\">")
                block.components.forEach { component ->
                    if (component.isEquation) {
                        val normalized = MathJaxInputNormalizer.insertSpaceBeforeDigitScriptBrace(component.text)
                        append("<span class=\"math-fragment\" data-original=\"")
                            .append(component.originalText.escapeHtml())
                            .append("\">")
                        if (component.type.inline) {
                            append("\\(").append(normalized.escapeHtml()).append("\\)")
                        } else {
                            append("\\[").append(normalized.escapeHtml()).append("\\]")
                        }
                        append("</span>")
                    } else {
                        append(
                            component
                                .textForLayout(configuration.blockMode)
                                .escapeHtml()
                                .replace("\n", "<br>"),
                        )
                    }
                }
                if (wrapsDisplayEquation) append("</div>")
            }
        }
        val fontSize = configuration.fontSize.value.coerceAtLeast(1f)
        val foreground = configuration.foregroundColor.cssColor()
        val imageRenderingMode = configuration.imageRenderingMode.resolvedFor(source)
        val imageRenderingClass = when (imageRenderingMode) {
            LaTeXImageRenderingMode.Template -> "image-template"
            LaTeXImageRenderingMode.Original -> "image-original"
        }
        val imageRenderingName = imageRenderingClass.removePrefix("image-")
        val blockAlignment = configuration.blockAlignment.cssTextAlign
        val contentClass = if (alwaysInline) "always-inline" else "block-views"
        val displayScaleCandidates = LaTeXDisplayEquationLayoutResolver
            .candidateScales(configuration.minimumDisplayScale)
            .joinToString(separator = ",") { it.toString() }
        val lenientPackageLoads = if (configuration.errorMode.keepsLenientMathJaxPackages) {
            ", '[tex]/noerrors', '[tex]/noundefined'"
        } else {
            ""
        }
        val lenientPackages = if (configuration.errorMode.keepsLenientMathJaxPackages) {
            ", 'noerrors', 'noundefined'"
        } else {
            ""
        }
        val errorMode = configuration.errorMode.javascriptName
        val safeRenderIdentifier = renderIdentifier.escapeJavaScriptSingleQuoted()

        return """
            <!doctype html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
                <style>
                    html, body {
                        background: transparent;
                        color: $foreground;
                        font-size: ${fontSize}px;
                        line-height: 1.35;
                        margin: 0;
                        padding: 0;
                        overflow-wrap: anywhere;
                    }
                    body { width: 100%; }
                    mjx-container { margin: 0 0.08em; }
                    #math-content.image-template mjx-container {
                        color: $foreground !important;
                    }
                    mjx-container[display="true"] {
                        display: inline-block !important;
                        margin: 0.35em 0;
                        overflow: visible;
                    }
                    #math-content.always-inline mjx-container[display="true"] {
                        margin: 0 0.08em;
                    }
                    .display-equation {
                        box-sizing: border-box;
                        width: 100%;
                        padding: 0 0.16em;
                        text-align: $blockAlignment;
                        overflow-x: hidden;
                        overflow-y: hidden;
                        white-space: nowrap;
                    }
                    .math-fragment-fallback { white-space: pre-wrap; }
                    #render-diagnostic {
                        display: none;
                        color: rgb(219, 41, 41);
                        font-family: monospace;
                        font-size: 11px;
                        font-weight: 500;
                        line-height: 1.25;
                        margin-top: 4px;
                        white-space: pre-wrap;
                    }
                </style>
                <script>
                    window.MathJax = {
                        loader: {
                            load: ['[tex]/ams', '[tex]/newcommand'$lenientPackageLoads]
                        },
                        tex: {
                            packages: {'[+]': ['ams', 'newcommand'$lenientPackages]},
                            inlineMath: [['\\(', '\\)']],
                            displayMath: [['\\[', '\\]']],
                            processEscapes: true
                        },
                        svg: { fontCache: 'local' },
                        startup: { typeset: false }
                    };
                </script>
                <script defer src="tex-svg-full.js"></script>
            </head>
            <body>
                <main
                    id="math-content"
                    class="$contentClass $imageRenderingClass"
                    data-image-rendering-mode="$imageRenderingName"
                >$content</main>
                <div id="render-diagnostic" role="alert" aria-live="polite"></div>
                <script>
                    const renderIdentifier = '$safeRenderIdentifier';
                    const errorMode = '$errorMode';
                    const displayScaleCandidates = [$displayScaleCandidates];
                    const displayAlignment = '$blockAlignment';
                    const displayWidthTolerance =
                        ${LaTeXDisplayEquationLayoutResolver.WidthTolerance};

                    function layoutDisplayEquations(force) {
                        document.querySelectorAll('.display-equation').forEach(function (wrapper) {
                            const wrapperStyle = window.getComputedStyle(wrapper);
                            const horizontalInset =
                                Number.parseFloat(wrapperStyle.paddingLeft) +
                                Number.parseFloat(wrapperStyle.paddingRight);
                            const availableWidth = wrapper.clientWidth - horizontalInset;
                            if (!Number.isFinite(availableWidth) || availableWidth <= 0) return;
                            if (
                                !force &&
                                Number(wrapper.dataset.availableWidth) === availableWidth
                            ) {
                                return;
                            }

                            const math = wrapper.querySelector('mjx-container[display="true"]');
                            const svg = math ? math.querySelector('svg') : null;
                            if (!math || !svg) return;

                            let intrinsicWidth = Number(svg.dataset.intrinsicWidth);
                            let intrinsicHeight = Number(svg.dataset.intrinsicHeight);
                            if (
                                !Number.isFinite(intrinsicWidth) ||
                                !Number.isFinite(intrinsicHeight) ||
                                intrinsicWidth <= 0 ||
                                intrinsicHeight <= 0
                            ) {
                                const intrinsicBounds = svg.getBoundingClientRect();
                                intrinsicWidth = intrinsicBounds.width;
                                intrinsicHeight = intrinsicBounds.height;
                                svg.dataset.intrinsicWidth = String(intrinsicWidth);
                                svg.dataset.intrinsicHeight = String(intrinsicHeight);
                            }
                            if (
                                !Number.isFinite(intrinsicWidth) ||
                                !Number.isFinite(intrinsicHeight) ||
                                intrinsicWidth <= 0 ||
                                intrinsicHeight <= 0
                            ) {
                                return;
                            }

                            let scale = displayScaleCandidates[
                                displayScaleCandidates.length - 1
                            ];
                            for (const candidate of displayScaleCandidates) {
                                if (
                                    intrinsicWidth * candidate <=
                                    availableWidth + displayWidthTolerance
                                ) {
                                    scale = candidate;
                                    break;
                                }
                            }

                            const renderedWidth = intrinsicWidth * scale;
                            const renderedHeight = intrinsicHeight * scale;
                            const requiresScrolling =
                                renderedWidth > availableWidth + displayWidthTolerance;
                            svg.style.width = renderedWidth + 'px';
                            svg.style.height = renderedHeight + 'px';
                            wrapper.style.textAlign =
                                requiresScrolling ? 'left' : displayAlignment;
                            wrapper.style.overflowX =
                                requiresScrolling ? 'auto' : 'hidden';
                            wrapper.dataset.availableWidth = String(availableWidth);
                            wrapper.dataset.renderScale = String(scale);
                            wrapper.dataset.requiresScrolling =
                                requiresScrolling ? 'true' : 'false';
                        });
                    }

                    function reportHeight() {
                        const height = Math.max(
                            document.body.scrollHeight,
                            document.documentElement.scrollHeight
                        );
                        if (window.BrainblastMathJax) {
                            window.BrainblastMathJax.onHeight(renderIdentifier, height);
                        }
                    }

                    function errorMessage(error) {
                        if (error && typeof error.message === 'string') {
                            return error.message;
                        }
                        return String(error);
                    }

                    function fragmentErrorMessages(fragment) {
                        const messages = Array.from(
                            fragment.querySelectorAll(
                                '[data-mjx-error], [data-mml-node="merror"]'
                            )
                        ).map(function (node) {
                            return (
                                node.getAttribute('data-mjx-error') ||
                                node.textContent ||
                                ''
                            ).trim();
                        }).filter(function (message) {
                            return message.length > 0;
                        });
                        return Array.from(new Set(messages));
                    }

                    function showFallback(fragment, message) {
                        const fallback = document.createElement('span');
                        fallback.className = 'math-fragment-fallback';
                        fallback.textContent =
                            errorMode === 'error'
                                ? message
                                : fragment.dataset.original || fragment.textContent || '';
                        fragment.replaceChildren(fallback);
                    }

                    function typesetFragment(fragment) {
                        return MathJax.typesetPromise([fragment])
                            .then(function () {
                                const messages = fragmentErrorMessages(fragment);
                                if (
                                    messages.length > 0 &&
                                    (errorMode === 'original' || errorMode === 'error')
                                ) {
                                    showFallback(fragment, messages.join('\n'));
                                }
                                return messages;
                            })
                            .catch(function (error) {
                                const message = errorMessage(error);
                                showFallback(fragment, message);
                                return [message];
                            });
                    }

                    function reportErrors(messages) {
                        const uniqueMessages = Array.from(new Set(messages));
                        if (uniqueMessages.length === 0) return;
                        const combinedMessage = uniqueMessages.join('\n');
                        if (errorMode === 'renderedWithDiagnostic') {
                            const diagnostic = document.getElementById('render-diagnostic');
                            diagnostic.textContent = combinedMessage;
                            diagnostic.style.display = 'block';
                        }
                        if (window.BrainblastMathJax) {
                            window.BrainblastMathJax.onError(
                                renderIdentifier,
                                combinedMessage
                            );
                        }
                    }

                    window.addEventListener('load', function () {
                        MathJax.startup.promise
                            .then(function () {
                                const fragments = Array.from(
                                    document.querySelectorAll('.math-fragment')
                                );
                                const messages = [];
                                let sequence = Promise.resolve();
                                fragments.forEach(function (fragment) {
                                    sequence = sequence
                                        .then(function () {
                                            return typesetFragment(fragment);
                                        })
                                        .then(function (fragmentMessages) {
                                            messages.push.apply(messages, fragmentMessages);
                                        });
                                });
                                return sequence.then(function () {
                                    return messages;
                                });
                            })
                            .then(function (messages) {
                                reportErrors(messages);
                                layoutDisplayEquations(true);
                                reportHeight();
                                if (window.BrainblastMathJax) {
                                    window.BrainblastMathJax.onReady(renderIdentifier);
                                }
                            })
                            .catch(function (error) {
                                const message = errorMessage(error);
                                reportErrors([message]);
                                reportHeight();
                            });
                    });

                    let resizeFrame = null;
                    new ResizeObserver(function () {
                        if (resizeFrame !== null) {
                            cancelAnimationFrame(resizeFrame);
                        }
                        resizeFrame = requestAnimationFrame(function () {
                            resizeFrame = null;
                            layoutDisplayEquations(false);
                            reportHeight();
                        });
                    }).observe(document.documentElement);
                </script>
            </body>
            </html>
        """.trimIndent()
    }

    private fun String.escapeHtml(): String = buildString(length) {
        this@escapeHtml.forEach { character ->
            append(
                when (character) {
                    '&' -> "&amp;"
                    '<' -> "&lt;"
                    '>' -> "&gt;"
                    '"' -> "&quot;"
                    '\'' -> "&#39;"
                    else -> character
                },
            )
        }
    }

    private fun String.escapeJavaScriptSingleQuoted(): String =
        replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace("\r", "\\r")
            .replace("\n", "\\n")

    private fun Color.cssColor(): String {
        if (this == Color.Unspecified) return "#111111"
        val argb = toArgb()
        val red = argb shr 16 and 0xFF
        val green = argb shr 8 and 0xFF
        val blue = argb and 0xFF
        val alpha = (argb ushr 24) / 255f
        return "rgba($red,$green,$blue,$alpha)"
    }
}
