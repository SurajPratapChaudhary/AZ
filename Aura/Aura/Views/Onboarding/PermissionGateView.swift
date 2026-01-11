import SwiftUI

struct PermissionGateView: View {
    @StateObject private var manager = PermissionManager()
    var onComplete: () -> Void
    
    // Alert state for when permission is denied and we need to send user to settings
    @State private var showSettingsAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Enable access")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                
                // Permission Rows
                VStack(spacing: 16) {
                    PermissionRow(
                        title: "Camera",
                        subtitle: "Required",
                        state: manager.camera
                    )
                    
                    PermissionRow(
                        title: "Photos",
                        subtitle: "Required",
                        state: manager.photos
                    )
                    
                    PermissionRow(
                        title: "Notifications",
                        subtitle: "Recommended",
                        state: manager.notifications
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Bottom Button
                Button {
                    handleAction()
                } label: {
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("AccentColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
        .task { await manager.refresh() }
        .alert("Permission Required", isPresented: $showSettingsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: manager.camera) { _, _ in checkAll() }
        .onChange(of: manager.photos) { _, _ in checkAll() }
        .onChange(of: manager.notifications) { _, _ in checkAll() }
    }
    
    private var buttonTitle: String {
        if manager.camera != .authorized { return "Enable Camera" }
        if manager.photos != .authorized { return "Enable Photos" }
        if manager.notifications != .authorized { return "Enable Notifications" }
        return "Start"
    }
    
    private func handleAction() {
        Task {
            if manager.camera != .authorized {
                if manager.camera == .denied {
                    alertMessage = "Camera access is denied. Please enable it in Settings."
                    showSettingsAlert = true
                } else {
                    _ = await manager.requestCamera()
                }
                return
            }
            
            if manager.photos != .authorized {
                if manager.photos == .denied {
                    alertMessage = "Photo library access is denied. Please enable it in Settings."
                    showSettingsAlert = true
                } else {
                    _ = await manager.requestPhotos()
                }
                return
            }
            
            if manager.notifications != .authorized {
                if manager.notifications == .denied {
                     // Notifications are recommended, maybe we skip if denied? 
                     // Or force settings? Usually recommended means skippable.
                     // But design implies sequential flow.
                     // Let's ask. If denied previously, we might show alert or just proceed.
                     // For now, prompt settings if denied, allowing user to manually fix or we just proceed if user insists?
                     // Let's assume strict flow for now, prompting settings.
                     alertMessage = "Notifications are disabled. Please enable them in Settings."
                     showSettingsAlert = true
                } else {
                    _ = await manager.requestNotifications()
                }
                return
            }
            
            // All good
            onComplete()
        }
    }
    
    private func checkAll() {
        // If all strictly required are authorized (Camera & Photos), we COULD let them pass,
        // but the UI flow seems step-by-step.
        // We will just let the button update.
    }
}

struct PermissionRow: View {
    let title: String
    let subtitle: String
    let state: PermissionManager.PermissionState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(state == .authorized ? Color("AccentColor") : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Text(state == .authorized ? "Granted" : "Not Granted")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    PermissionGateView(onComplete: {})
}
