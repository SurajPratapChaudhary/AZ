//
//  PhotoResultsView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//


import SwiftUI

struct PhotoResultsView: View {
    let rawPreview: UIImage
    let result: PhotoJobResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Results")
                    .font(.system(size: 26, weight: .bold))
                    .padding(.top, 12)

                Text("Style: \(result.style.rawValue)")
                    .foregroundStyle(.secondary)

                Image(uiImage: rawPreview)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(Array(result.variants.enumerated()), id: \.offset) { _, url in
                        if let img = UIImage(contentsOfFile: url.path) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }
}
