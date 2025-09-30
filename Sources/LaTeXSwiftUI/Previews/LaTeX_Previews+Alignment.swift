//
//  LaTeX_Previews+Alignment.swift
//  LaTeXSwiftUI
//

import SwiftUI

#Preview("Block Alignment - Leading") {
  VStack(spacing: 20) {
    Text("Leading Alignment")
      .font(.headline)

    LaTeX("""
    This is some text before the equation.

    $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$

    This is some text after the equation.
    """)
    .blockAlignment(.leading)
    .padding()
    .border(Color.gray)
  }
  .padding()
  .frame(width: 400)
}

#Preview("Block Alignment - Center") {
  VStack(spacing: 20) {
    Text("Center Alignment")
      .font(.headline)

    LaTeX("""
    This is some text before the equation.

    $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$

    This is some text after the equation.
    """)
    .blockAlignment(.center)
    .padding()
    .border(Color.gray)
  }
  .padding()
  .frame(width: 400)
}

#Preview("Block Alignment - Trailing") {
  VStack(spacing: 20) {
    Text("Trailing Alignment")
      .font(.headline)

    LaTeX("""
    This is some text before the equation.

    $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$

    This is some text after the equation.
    """)
    .blockAlignment(.trailing)
    .padding()
    .border(Color.gray)
  }
  .padding()
  .frame(width: 400)
}

#Preview("Block Alignment - All Three") {
  VStack(spacing: 40) {
    VStack(alignment: .leading, spacing: 10) {
      Text("Leading")
        .font(.caption)
        .foregroundColor(.secondary)

      LaTeX("$$E = mc^2$$")
        .blockAlignment(.leading)
        .padding()
        .border(Color.red.opacity(0.3))
    }

    VStack(alignment: .leading, spacing: 10) {
      Text("Center")
        .font(.caption)
        .foregroundColor(.secondary)

      LaTeX("$$E = mc^2$$")
        .blockAlignment(.center)
        .padding()
        .border(Color.blue.opacity(0.3))
    }

    VStack(alignment: .leading, spacing: 10) {
      Text("Trailing")
        .font(.caption)
        .foregroundColor(.secondary)

      LaTeX("$$E = mc^2$$")
        .blockAlignment(.trailing)
        .padding()
        .border(Color.green.opacity(0.3))
    }
  }
  .padding()
  .frame(width: 500)
}
