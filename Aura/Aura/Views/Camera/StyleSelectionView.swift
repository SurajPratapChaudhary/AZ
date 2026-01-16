import SwiftUI

struct StyleSelectionView: View {
    let image: UIImage
    let onBack: () -> Void
    let onUpgrade: (AuraStyle) -> Void
    
    @State private var selectedStyle: AuraStyle = .luxury
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            VStack(alignment: .leading, spacing: 24) {
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
            .background {
                Color.black
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                    .ignoresSafeArea()
            }
        }
        .background {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .screenWidth, maxHeight: .screenHeight)
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, content: Header)
    }
    
    @ViewBuilder func StyleOptions() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Styles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.leading, 20)
                .padding(.top, 4)
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
    }
    
    @ViewBuilder func Texts() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image 1")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.leading, 20)
            
            Text("Choose a style to enhance your photo")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.leading, 20)
        }
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
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .tint(.primary)
        .opacity(0.7)
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
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color("AccentColor") : Color.clear, lineWidth: 3)
        )
        .padding(.vertical, 4)
    }
}

#Preview {
    // Create a sample UIImage for preview purposes
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600))
    let sample = renderer.image { ctx in
        let bounds = CGRect(origin: .zero, size: CGSize(width: 800, height: 600))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradientColors: [CGColor] = [
            UIColor.systemPink.cgColor,
            UIColor.systemPurple.cgColor,
            UIColor.systemTeal.cgColor,
            UIColor.systemGreen.cgColor
        ]
        let locations: [CGFloat] = [0.0, 0.33, 0.66, 1.0]
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: locations) {
            let startPoint = CGPoint(x: 0, y: 0)
            let endPoint = CGPoint(x: bounds.width, y: bounds.height)
            ctx.cgContext.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
        
        // Optional: overlay a subtle vignette to give depth
        ctx.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.15).cgColor)
        ctx.cgContext.fill(bounds.insetBy(dx: -1, dy: -1))
        
        // Optional label to identify the preview image
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        let text = NSString(string: "")
        text.draw(in: CGRect(x: 0, y: bounds.midY - 24, width: bounds.width, height: 48), withAttributes: attrs)
    }
    
    return StyleSelectionView(image: sample, onBack: {}, onUpgrade: { _ in })
}

