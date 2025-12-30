//
//  CameraView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import SwiftUI

struct CameraView: View {
    @ObservedObject var vm: CameraFlowViewModel

    var body: some View {
        ZStack {
            CameraPreviewView(session: vm.cameraService.session)
                .ignoresSafeArea()

            SafeFrameOverlay()

            VStack(spacing: 10) {
                HStack {
                    GuidanceBadge(state: vm.guidance)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                StyleSelectorPill(selected: $vm.selectedStyle)
                    .padding(.bottom, 14)

                ShutterButton {
                    vm.shutterTapped()
                }
                .padding(.bottom, 28)
            }
        }
        .background(Color.black)
    }
}
