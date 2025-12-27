//
//  ProcessingView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct ProcessingView: View {
    let rawPreview: UIImage
    let jobId: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(uiImage: rawPreview)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 18)

            ProgressView("Processing…")
                .tint(Color(hex: "01A67C"))

            // ID removed for premium experience
            // Text("Job: \(jobId.prefix(8))") ...

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }
}
