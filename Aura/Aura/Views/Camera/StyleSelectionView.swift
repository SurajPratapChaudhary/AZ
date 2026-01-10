import SwiftUI

struct StyleSelectionView: View {
    let image: UIImage
    let onBack: () -> Void
    let onUpgrade: (AuraStyle) -> Void
    
    @State private var selectedStyle: AuraStyle = .luxury
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Spacer()
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 4)
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    Texts()
                    
                    StyleOptions()
                    
                    MainButtons()
                }
                .background(Color(UIColor.secondarySystemBackground).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.bottom, -30)
            }
        }
        .safeAreaInset(edge: .top, content: Header)
    }
    
    @ViewBuilder func StyleOptions() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AuraStyle.allCases, id: \.self) { style in
                    StyleOptionCard(style: style, isSelected: selectedStyle == style)
                        .onTapGesture {
                            withAnimation { selectedStyle = style }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder func Texts() -> some View {
        Text("Image 1")
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.leading, 20)
        
        Text("Choose a style to enhance your photo")
            .font(.subheadline)
            .foregroundStyle(.gray)
            .padding(.leading, 20)
        
        Text("Styles")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.leading, 20)
            .padding(.top, 4)

    }
    
    @ViewBuilder func MainButtons() -> some View {
        Button {
            onUpgrade(selectedStyle)
        } label: {
            Text("Upgrade Photo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("AccentColor"))
                .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        
        Button {
            onBack()
        } label: {
            Text("Change Photo")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder func Header() -> some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Post Preview")
                .font(.headline)
                .foregroundStyle(.white)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
    }
}

struct StyleOptionCard: View {
    let style: AuraStyle
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            
            Text(style.rawValue.capitalized)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(4)
                .background(Color.black.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color("AccentColor") : Color.clear, lineWidth: 2)
        )
        .padding(.vertical, 4)
    }
}
