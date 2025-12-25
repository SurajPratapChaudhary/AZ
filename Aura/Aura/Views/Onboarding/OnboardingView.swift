//
//  OnboardingView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var container: AppContainer
    @AppStorage("aura.didOnboard") private var didOnboard = false

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Text("Shoot. We upgrade the scene.")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            Text("No filters. No retouching. Just premium results.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)

            Spacer()

            Button {
                Task {
                    let cam = await container.permissions.requestCamera()
                    let pho = await container.permissions.requestPhotos()
                    _ = await container.permissions.requestNotifications()

                    if cam && pho {
                        didOnboard = true
                    }
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "01A67C"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 18)
            }

            Spacer().frame(height: 18)
        }
        .padding(.top, 30)
        .background(Color.black.ignoresSafeArea())
        .task { await container.permissions.refresh() }
    }
}
