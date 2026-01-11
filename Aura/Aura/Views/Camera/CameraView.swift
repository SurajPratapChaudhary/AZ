//
//  CameraView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 24/12/25.
//

import SwiftUI

struct CameraView: View {
    @ObservedObject var vm: CameraFlowViewModel
    @State private var showStyleSelector = false

    var body: some View {
        ZStack {
            CameraPreviewView(session: vm.cameraService.session)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tap anywhere to dismiss selector if open
                    if showStyleSelector {
                        withAnimation { showStyleSelector = false }
                    }
                }

            // Screenshot SHOWS corners. Keep SafeFrameOverlay.
            SafeFrameOverlay()

            VStack(spacing: 0) {
                // Top Bar Area
                VStack(spacing: 12) {
                    HStack {
                        Text("Camera")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        if !showStyleSelector {
                            Button {
                                withAnimation { showStyleSelector = true }
                            } label: {
                                Text(vm.selectedStyle.rawValue.capitalized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                        
                        Text("360 Credits")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Style Selector Row (Visible only when toggled)
                    if showStyleSelector {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(AuraStyle.allCases, id: \.self) { style in
                                    Button {
                                        withAnimation {
                                            vm.selectedStyle = style
                                            // Optional: Close on select? Or keep open?
                                            // Screenshot 1 implies it stays open or is a mode.
                                            // User usually wants to see the effect. We'll keep it open.
                                        }
                                    } label: {
                                        Text(style.rawValue.capitalized)
                                            .font(.system(size: 13, weight: vm.selectedStyle == style ? .semibold : .regular))
                                            .foregroundStyle(vm.selectedStyle == style ? Color.black : Color.white) // Black text on green
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                ZStack {
                                                    if vm.selectedStyle == style {
                                                        Color("AccentColor")
                                                    } else {
                                                        Color.clear
                                                    }
                                                }
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                // Guidance (Subtle)
                if vm.guidance != .good {
                    Text(vm.guidance.description)
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .padding(.top, 8)
                        .transition(.opacity)
                }

                Spacer()
                
                // Shutter Button (Center Bottom)
                ShutterButton {
                    vm.shutterTapped()
                }
                .padding(.bottom, 30)
                .opacity(showStyleSelector ? 0.0 : 1.0) // Hide shutter when selecting style? Or keep?
                // Screenshot 1 doesn't show shutter clearly, but usually you can shoot.
                // However, "Select filter" might be a distinct mode.
                // Let's keep shutter visible but maybe dim? 
                // Wait, Screenshot 1 cuts off the bottom.
                // Screenshot 0 (Default) has Shutter.
                // Logic: If I select a filter, I might want to shoot immediately.
                // I will keep it visible.
            }
        }
        .background(Color.black)
    }
}

#Preview {
    @MainActor func makeVM() -> CameraFlowViewModel {
        let vm = CameraFlowViewModel()
        vm.guidance = .lowLight
        return vm
    }
    
    return CameraView(vm: makeVM())
}
