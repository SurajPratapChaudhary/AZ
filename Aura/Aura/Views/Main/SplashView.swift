//
//  SplashView.swift
//  Aura
//
//  Created by Alijonov Shohruhmirzo on 10/01/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        Image(.mainBackground)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                Text("AURA")
                    .font(.system(size: 24, weight: .semibold))
            }
    }
}

#Preview {
    SplashView()
}
