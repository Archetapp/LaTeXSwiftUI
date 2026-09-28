# LaTeXSwiftUI to LaTeXCompose parity matrix

Last audited: 2026-07-28

This matrix treats the Swift implementation as a read-only behavioral reference. The audit covered
the public LaTeXSwiftUI API and active Brainblast call sites. No Swift source, Swift package, Xcode
file, or backend file was changed or built.

## Active Brainblast usage

Active question, answer, bookmark, table, and widget surfaces use LaTeXSwiftUI for:

- inline equations embedded in prose;
- standalone display equations;
- equation-only parsing;
- forced inline block layout;
- empty/standard render transitions;
- original/template image rendering;
- leading and centered block alignment;
- rendered-error diagnostics.

The active MarkdownLaTeX display path attempts widths at 100%, 90%, 80%, 70%, and 65%, in that
order, and only then exposes a horizontally scrollable 65% rendering. That behavior is the reference
for `LaTeXDisplayEquationLayoutResolver`.

## API and behavior

| Swift surface or behavior | Swift default / active use | Android counterpart | Status / evidence |
| --- | --- | --- | --- |
| `LaTeX(_:)`, `latex` source | Required source string | `LaTeX(source:)` | Implemented; parser and HTML unit tests |
| `ParsingMode.onlyEquations` | Dominant active mode | `LaTeXParsingMode.OnlyEquations` | Implemented; parser tests |
| `ParsingMode.all` / raw text and equations | Supported | `LaTeXParsingMode.All` | Implemented; parser tests |
| `$...$`, `\(...\)` inline delimiters | Supported | `LaTeXParser` | Implemented; parser tests |
| `$$...$$`, `\[...\]`, `equation` / `equation*` blocks | Supported | `LaTeXParser` | Implemented; parser tests |
| Escaped delimiters | Processed by parser/configuration | Parser escape handling | Partially implemented; parser behavior exists, but there is no public `processEscapes` configuration yet |
| Offline equation rendering | MathJaxSwift/SwiftDraw | Bundled MathJax 3.2.2 SVG in network-blocked `WebView` | Implemented; HTML tests and device fixture |
| Font size | Environment/configuration driven | `LaTeXConfiguration.fontSize` | Implemented; HTML test |
| Foreground color | Environment/configuration driven | `LaTeXConfiguration.foregroundColor` | Implemented; HTML test |
| `BlockAlignment.leading/center/trailing` | Leading library default; active MarkdownLaTeX commonly centers | `LaTeXBlockAlignment` | Implemented 2026-07-27; HTML test and device fixture |
| Width-fitted display equation | 1.0, .9, .8, .7, .65, then scroll | `LaTeXDisplayEquationLayoutResolver` plus MathJax DOM layout | Implemented 2026-07-27; resolver tests, HTML contract test, and device fixture |
| Multiline dynamic height | Renderer-derived size | Generation-scoped JavaScript height bridge into Compose | Partial; display/inline/error fixtures cover representative content and malformed-to-valid replacement remeasurement, but a broader typography matrix remains |
| Baseline / text attachment alignment | Swift renderer metrics | WebView inline box | Partial; the `alwaysInline` fixture proves representative display-style math in wrapped prose, but no systematic cross-platform baseline corpus exists yet |
| `BlockMode.alwaysInline` | Used by active prose/question surfaces; trims boundary newlines and flattens blocks while preserving display-style math | `LaTeXBlockMode.AlwaysInline` | Implemented 2026-07-28; parser/component and HTML contracts plus inspected API-36 fixture |
| `BlockMode.blockViews` | Library default | `LaTeXBlockMode.BlockViews` | Implemented as the Android default; configuration and HTML contracts plus comparison fixture |
| `BlockMode.blockText` | Supported by library | No counterpart | Missing; port only if reachable Android call sites require it |
| `EquationNumberMode` and numbering controls | Public API | No counterpart | Missing |
| `ErrorMode` including rendered diagnostic | `original` default; active `renderedWithDiagnostic` display/answer use | `LaTeXErrorMode` plus `onRenderError` | Implemented 2026-07-28; per-fragment strict Original/Error fallback, lenient Rendered/RenderedWithDiagnostic packages, exact authored delimiters, deduplicated red diagnostics, generation-scoped callbacks, JVM HTML contracts, and inspected failure/recovery fixture |
| `unencoded` | Public input mode | No counterpart | Missing |
| `RenderingStyle.empty` and default `original` | Active consumer paths use `.empty` for Markdown/rich explanation/game-answer surfaces; direct question/history/bookmark renders use the package-default `.original` | `LaTeXRenderingStyle.Empty` and default `Original`; the WebView is zero-height, transparent, and removed from accessibility until the generation-scoped ready callback | Implemented 2026-07-28; loading-state semantics and inspected API-36 fixture prove no source flash versus exact authored-source fallback |
| `RenderingStyle.redactedOriginal`, `progress`, and `wait` | Preview/deprecated/admin-only in the audited consumer graph | `LaTeXRenderingStyle.RedactedOriginal`, `Progress`, and `Wait` | API counterpart implemented; lower-priority runtime matrix remains because these cases are not consumer-reachable |
| `renderingAnimation` | Default `.none`; explicit animation appears only in previews/deprecated UI | No active Android transition | Excluded from active parity; do not invent a consumer animation. The inactive progress placeholder respects disabled platform animators. |
| Original/template image rendering mode | Template is the source default. Active Markdown/rich explanation paths choose original for `\color`/`\textcolor` so authored ink survives; uncolored math adopts the environment tint. | `LaTeXImageRenderingMode.Template` default and `Original`; template automatically promotes to original for color commands | Implemented 2026-07-28; HTML contracts, per-mode pixel assertions, and inspected API-36 fixture prove theme tint, explicit red/blue ink, and automatic green/purple preservation |
| Fixed x-height / fixed display scale | Public configuration | `minimumDisplayScale` only | Partial |
| Data/image cache, preload, prewarm, release | Public lifecycle/performance API | WebView lifecycle only | Missing |
| Accessibility | Swift text/image accessibility paths | WebView document semantics plus caller modifier | Partial; TalkBack labels, traversal, and error announcements need dedicated tests |
| `displayMode` compatibility property | Android prototype property | Present but not mapped to a Swift public contract | Legacy/unused; do not treat as parity evidence |

## Verification fixtures

- JVM layout contract: `LaTeXDisplayEquationLayoutTest`
- HTML generation contract: `MathJaxHtmlDocumentTest`
- Block-mode default contract: `LaTeXConfigurationTest`
- Named Compose/device rendering: `LaTeXDisplayLayoutInstrumentedTest`
- Device artifact: `latex-display-layout-fixture.png`, written by the instrumentation test
- Named forced-inline rendering: `LaTeXAlwaysInlineInstrumentedTest`
- Device artifact: `latex-always-inline-phone-fixture.png`, written by the instrumentation test
- Named error-policy/recovery rendering: `LaTeXErrorPolicyInstrumentedTest`
- Device artifact: `latex-error-policy-phone-fixture.png`, written by the instrumentation test
- Named loading-style/image-mode rendering: `LaTeXRenderingStyleInstrumentedTest`
- Device artifact: `latex-rendering-style-phone-fixture.png`, written by the instrumentation test

## Remaining priority

1. Establish a baseline and multiline screenshot corpus at app typography sizes.
2. Add render reuse/prewarming only after measurements show it is needed on active journeys.
3. Complete TalkBack semantics, traversal, and diagnostic-announcement testing during hardening.
4. Revisit inactive rendering animation only if it becomes consumer-reachable.
