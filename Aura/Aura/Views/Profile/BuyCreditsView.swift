
import SwiftUI

struct BuyCreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "020202").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Buy Credits")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Spacer for alignment
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Credits")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("Use credits to create premium photos and reels.")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            CreditOptionCard(title: "Starter", credits: "10 Credits", price: "$4.99", unitPrice: "$0.50 per credit")
                            CreditOptionCard(title: "Popular", credits: "10 Credits", price: "$4.99", unitPrice: "$0.50 per credit", isHighlighted: false) // Mock data match
                            CreditOptionCard(title: "Best Value", credits: "10 Credits", price: "$4.99", unitPrice: "$0.50 per credit")
                        }
                    }
                    .padding()
                }
                
                VStack(spacing: 16) {
                    Text("Restore Purchases")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Button {
                        // Buy action
                    } label: {
                        Text("Buy Credits")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "68CC9F")) // Aura Green
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                }
                .padding(24)
                .background(Color(hex: "020202"))
            }
        }
    }
}

struct CreditOptionCard: View {
    let title: String
    let credits: String
    let price: String
    let unitPrice: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(credits)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(unitPrice)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            VStack {
                Text(price)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                // Bullet point mockup
                Circle()
                    .fill(.white)
                    .frame(width: 4, height: 4)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 2)
                    .opacity(0) // Just strictly following layout from screenshot if needed, but simple text is fine
            }
            .overlay(alignment: .trailing) {
                // Dot
                 Text("•")
                     .font(.system(size: 10))
                     .foregroundStyle(.white)
                     .offset(x: -50, y: 1) // Rough positioning for the dot in screenshot "• $4.99"
                     .opacity(0) // Screenshot implies bullet is part of design maybe
            }
            .overlay(alignment: .leading) {
                 Circle()
                     .fill(.white)
                     .frame(width: 4, height: 4)
                     .offset(x: -12)
            }
             
        }
        .padding(20)
        .background(Color(hex: "121214"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
