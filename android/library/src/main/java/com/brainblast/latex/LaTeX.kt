package com.brainblast.latex

import android.annotation.SuppressLint
import android.graphics.Color
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import java.util.concurrent.atomic.AtomicLong

/**
 * Offline TeX/LaTeX rendering for Compose.
 *
 * The view loads the bundled MathJax runtime from Android assets, converts equations to SVG in a
 * sandboxed WebView, and never permits network requests.
 */
@Composable
fun LaTeX(
    source: String,
    modifier: Modifier = Modifier,
    configuration: LaTeXConfiguration = LaTeXConfiguration(),
    parsingMode: LaTeXParsingMode = LaTeXParsingMode.OnlyEquations,
    renderingStyle: LaTeXRenderingStyle = LaTeXDefaults.renderingStyle,
    onRenderComplete: () -> Unit = {},
    onRenderError: (String) -> Unit = {},
) {
    val renderIdentifier = remember(source, configuration, parsingMode) {
        RenderIdentifierCounter.incrementAndGet().toString()
    }
    val html = remember(source, configuration, parsingMode, renderIdentifier) {
        MathJaxHtmlDocument.create(
            source = source,
            configuration = configuration,
            parsingMode = parsingMode,
            renderIdentifier = renderIdentifier,
        )
    }
    val currentOnRenderComplete by rememberUpdatedState(onRenderComplete)
    val currentOnRenderError by rememberUpdatedState(onRenderError)
    val currentRenderIdentifier by rememberUpdatedState(renderIdentifier)
    var renderedMetrics by remember { mutableStateOf("" to 0) }
    var renderedIdentifier by remember { mutableStateOf<String?>(null) }
    var webView by remember { mutableStateOf<WebView?>(null) }
    val density = LocalDensity.current
    val minimumHeight = with(density) { configuration.fontSize.toDp() * 1.5f }
    val renderedHeight = renderedMetrics
        .takeIf { (identifier, _) -> identifier == renderIdentifier }
        ?.second
        ?: 0
    val contentHeight = if (renderedHeight > 0) maxOf(renderedHeight.dp, minimumHeight) else minimumHeight
    val isRendered = renderedIdentifier == renderIdentifier

    Box(modifier = modifier) {
        AndroidView(
            factory = { context ->
                createMathJaxWebView(
                    context = context,
                    onHeight = { identifier, height ->
                        if (identifier == currentRenderIdentifier) {
                            renderedMetrics = identifier to height.coerceAtLeast(1)
                        }
                    },
                    onReady = { identifier ->
                        if (identifier == currentRenderIdentifier) {
                            renderedIdentifier = identifier
                            currentOnRenderComplete()
                        }
                    },
                    onError = { identifier, message ->
                        if (identifier == currentRenderIdentifier) {
                            currentOnRenderError(message)
                        }
                    },
                ).also {
                    webView = it
                    it.loadMathJaxDocument(html, renderIdentifier)
                }
            },
            update = { view ->
                view.importantForAccessibility = if (isRendered) {
                    View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
                } else {
                    View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
                }
                if (view.tag != renderIdentifier) {
                    view.loadMathJaxDocument(html, renderIdentifier)
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (isRendered) {
                        Modifier.heightIn(min = minimumHeight, max = contentHeight)
                    } else {
                        Modifier.height(0.dp)
                    },
                )
                .alpha(if (isRendered) 1f else 0f),
        )

        if (!isRendered) {
            LaTeXLoadingContent(
                source = source,
                renderingStyle = renderingStyle,
                fontSize = configuration.fontSize,
                foregroundColor = configuration.foregroundColor,
            )
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            webView?.apply {
                stopLoading()
                removeJavascriptInterface(JAVASCRIPT_BRIDGE_NAME)
                destroy()
            }
            webView = null
        }
    }
}

@SuppressLint("SetJavaScriptEnabled")
private fun createMathJaxWebView(
    context: android.content.Context,
    onHeight: (String, Int) -> Unit,
    onReady: (String) -> Unit,
    onError: (String, String) -> Unit,
): WebView = WebView(context).apply {
    setBackgroundColor(Color.TRANSPARENT)
    isVerticalScrollBarEnabled = false
    isHorizontalScrollBarEnabled = false
    overScrollMode = WebView.OVER_SCROLL_NEVER
    settings.apply {
        javaScriptEnabled = true
        domStorageEnabled = false
        allowFileAccess = true
        allowContentAccess = false
        blockNetworkLoads = true
        cacheMode = WebSettings.LOAD_NO_CACHE
        mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
    }
    webViewClient = WebViewClient()
    addJavascriptInterface(
        MathJaxBridge(
            reportHeight = { identifier, height -> post { onHeight(identifier, height) } },
            reportReady = { identifier -> post { onReady(identifier) } },
            reportError = { identifier, message -> post { onError(identifier, message) } },
        ),
        JAVASCRIPT_BRIDGE_NAME,
    )
}

private fun WebView.loadMathJaxDocument(
    html: String,
    renderIdentifier: String,
) {
    tag = renderIdentifier
    loadDataWithBaseURL(
        MATHJAX_ASSET_BASE_URL,
        html,
        "text/html",
        "UTF-8",
        null,
    )
}

private class MathJaxBridge(
    private val reportHeight: (String, Int) -> Unit,
    private val reportReady: (String) -> Unit,
    private val reportError: (String, String) -> Unit,
) {
    @JavascriptInterface
    fun onHeight(
        renderIdentifier: String,
        height: Int,
    ) {
        reportHeight(renderIdentifier, height)
    }

    @JavascriptInterface
    fun onReady(renderIdentifier: String) {
        reportReady(renderIdentifier)
    }

    @JavascriptInterface
    fun onError(
        renderIdentifier: String,
        message: String,
    ) {
        reportError(renderIdentifier, message)
    }
}

private val RenderIdentifierCounter = AtomicLong()
private const val JAVASCRIPT_BRIDGE_NAME = "BrainblastMathJax"
private const val MATHJAX_ASSET_BASE_URL = "file:///android_asset/mathjax/"
