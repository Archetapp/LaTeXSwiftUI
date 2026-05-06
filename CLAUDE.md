# LaTeXSwiftUI — Vendored Third-Party Fork

**Upstream:** github.com/colinc86/LaTeXSwiftUI. This directory is a working checkout of the Brainblast fork (github.com/Archetapp/LaTeXSwiftUI), pulled into the iOS workspace as a remote SPM dependency via `BrainBlastUI/Package.swift`.

**Treat as vendored — do not modify unless syncing from upstream or patching a specific bug.** If you need to patch, keep the diff surgical, document it in the commit message, and prefer upstreaming the fix.

## Purpose

Renders LaTeX equations as SwiftUI views by shelling out to `MathJaxSwift`, converting the SVG output via `SwiftDraw`, and caching per-equation renders. Used throughout Brainblast for inline and block math in question text, explanations, and admin tools. The entry point is the `LaTeX(_:)` view, configured via environment modifiers (`equationStyle`, `imageRenderingMode`, etc.).

## Consumers

Widest-used third-party dependency in the workspace — imported by 30+ files across `BrainblastUI` (RichExplanationView, MarkdownLaTeX, QuestionToolDataTable), `BrainblastGames` (DrawQuestion, SyncGame review views, SoloGame, GameContainer, RoundAnimation answer cards, ExplanationSheet), `BrainblastHome` (FlaggedReviewCard), `BrainblastMarkdownEditor` (EquationBlockEditor), and the Brainblast / BrainblastDev / BrainblastAdmin app targets.

## Build & test

```
cd LaTeXSwiftUI && swift build
cd LaTeXSwiftUI && swift test
```

## Don't touch

Everything under `Sources/LaTeXSwiftUI/` follows the upstream file layout (`LaTeX.swift`, `LaTeX+Configuration.swift`, `Models/`, `Views/`, `Styles/`, `Extensions/`, `Previews/`). Keep it that way so future upstream syncs are mechanical.

Brainblast-specific patches, if any, should be identifiable in `git log --oneline` against the upstream tag.
