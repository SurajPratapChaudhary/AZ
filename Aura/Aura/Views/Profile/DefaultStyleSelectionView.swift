
import SwiftUI

struct DefaultStyleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    let styles: [AuraStyle] = [.luxury, .cinematic, .clean, .editorial, .night]
    
    var body: some View {
        ZStack {
            Color(hex: "020202").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag Indicator
                 Capsule()
                     .fill(Color.white.opacity(0.3))
                     .frame(width: 40, height: 4)
                     .padding(.top, 12)
                     .padding(.bottom, 20)
                
                HStack {
                    Text("Set Default Style")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(styles, id: \.self) { style in
                            StyleOptionRow(style: style, isSelected: viewModel.defaultStyle == style) {
                                viewModel.setDefaultStyle(style)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Set As Default")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "68CC9F")) // Aura Green
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .padding(24)
            }
        }
        .presentationDetents([.height(600)])
        .presentationDragIndicator(.hidden) // We drew our own or use native
        .presentationCornerRadius(24)
    }
}

struct StyleOptionRow: View {
    let style: AuraStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(style.rawValue.capitalized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(isSelected ? 1 : 0.7))
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "68CC9F") : Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "68CC9F"))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding()
            .background(Color(hex: "121214"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "68CC9F").opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DefaultStyleSelectionView(viewModel: ProfileViewModel())
}
