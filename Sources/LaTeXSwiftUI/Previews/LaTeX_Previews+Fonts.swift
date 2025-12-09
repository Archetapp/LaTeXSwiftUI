//
//  LaTeX_Previews+Fonts.swift
//  LaTeXSwiftUI
//
//  Copyright (c) 2025 Colin Campbell
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformFont = UIFont
#else
import Cocoa
typealias PlatformFont = NSFont
#endif

struct LaTeX_Previews_Fonts: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Question header with improved layout
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Question")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        LaTeX("Choice A is correct. Adding $25$ to both sides of the given equation yields $5x=55$. Dividing both sides of this equation by $5$ yields $x=11$. Therefore, the value of $x-6$ is $11-6=5$.")
                    }
                }
                
                //      LaTeX("Hello, $\\LaTeX$!")
                //        .font(PlatformFont.preferredFont(forTextStyle: .title1))
                //
                //      LaTeX("Hello, $\\LaTeX$!")
                //        .font(PlatformFont.systemFont(ofSize: 36))
                //
                //      LaTeX("Hello, $\\LaTeX$!")
                //        .font(PlatformFont.boldSystemFont(ofSize: 25))
                //
                //      LaTeX("Hello, $\\LaTeX$!")
                //        .font(PlatformFont(name: "Avenir", size: 25)!)
            }
            .previewDisplayName("Fonts")
        }
    }
    
}
