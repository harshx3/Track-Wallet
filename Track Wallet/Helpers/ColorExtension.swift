//
//  ColorExtension.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/28/26.
//

import SwiftUI

struct AccountIconView: View {
    let account: Account
    var size: CGFloat = 36
    var cornerRadius: CGFloat = 8

    var body: some View {
        if let faviconURL = account.faviconURL {
            AsyncImage(url: faviconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                default:
                    sfSymbolIcon
                }
            }
        } else {
            sfSymbolIcon
        }
    }

    private var sfSymbolIcon: some View {
        Image(systemName: account.icon)
            .font(.system(size: size * 0.45))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(account.color.toColor)
            )
    }
}

extension String {
    var toColor: Color {
        switch self.lowercased() {
        case "blue":
            return .blue
        case "green":
            return .green
        case "orange":
            return .orange
        case "red":
            return .red
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "indigo":
            return .indigo
        case "teal":
            return .teal
        case "yellow":
            return .yellow
        case "cyan":
            return .cyan
        case "mint":
            return .mint
        case "brown":
            return .brown
        default:
            return .blue
        }
    }
}
