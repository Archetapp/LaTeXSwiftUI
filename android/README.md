# LaTeXCompose

Kotlin/Compose counterpart to LaTeXSwiftUI.

The public model, parser, and offline MathJax-to-SVG Compose renderer live here. The renderer uses
the bundled MathJax 3.2.2 browser distribution, blocks all network requests, and can be compared
against the existing MathJaxSwift/SwiftDraw implementation without changing the Swift package.

Display equations follow the active Brainblast iOS fitting contract: try 100%, 90%, 80%, 70%, and
65% in order, then allow horizontal scrolling at 65%. Leading, centered, and trailing display
alignment are configured with `LaTeXBlockAlignment`.

Block layout defaults to the source library's `BlockViews` behavior. Set
`LaTeXConfiguration(blockMode = LaTeXBlockMode.AlwaysInline)` for active prose surfaces that
flatten parsed block boundaries into one wrapping flow. This trims only boundary newlines from
text components and preserves display-style equation rendering within the inline flow.

Error handling defaults to `LaTeXErrorMode.Original`, matching the Swift package. `Original`
restores the exact authored delimited fragment, `Error` substitutes the MathJax message,
`Rendered` keeps lenient MathJax output, and `RenderedWithDiagnostic` retains that output while
adding the active Brainblast red diagnostic below it. Error callbacks carry render identifiers so
stale documents cannot resize or complete a replacement render.

The source-backed public API and behavior audit is recorded in
[`docs/LATEXSWIFTUI_PARITY_MATRIX.md`](docs/LATEXSWIFTUI_PARITY_MATRIX.md).

MathJax's Apache 2.0 license is included beside the bundled runtime in
`library/src/main/assets/mathjax`.

The pinned `tex-svg-full.js` SHA-256 is
`a4354ff94fd868aea0cc6eaaa79a57fda0588646fc46ee3700a349ee0a11cbe6`.
