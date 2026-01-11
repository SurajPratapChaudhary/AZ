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
                    if showStyleSelector {
                        withAnimation { showStyleSelector = false }
                    }
                }

            SafeFrameOverlay()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    
                    StyleOptions()
                }
                
                if vm.guidance != .good {
                    Text(vm.guidance.description)
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .padding(.top, 8)
                        .transition(.opacity)
                }

                Spacer()
                
                ShutterButton {
                    vm.shutterTapped()
                }
                .padding(.bottom, 30)
                .opacity(showStyleSelector ? 0.0 : 1.0)
            }
        }
        .background(Color.black)
        .safeAreaInset(edge: .top, content: Header)
    }
    
    @ViewBuilder func Header() -> some View {
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
                .font(.system(size: 14))
                .foregroundStyle(.primary .opacity(0.8))
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder func StyleOptions() -> some View {
        if showStyleSelector {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AuraStyle.allCases, id: \.self) { style in
                        Button {
                            withAnimation {
                                vm.selectedStyle = style
                            }
                        } label: {
                            Text(style.rawValue.capitalized)
                                .font(.system(size: 13, weight: vm.selectedStyle == style ? .semibold : .regular))
                                .foregroundStyle(vm.selectedStyle == style ? Color.black : Color.white)
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
}

#Preview {
    @MainActor func makeVM() -> CameraFlowViewModel {
        let vm = CameraFlowViewModel()
        vm.guidance = .lowLight
        return vm
    }
    
    return CameraView(vm: makeVM())
}
