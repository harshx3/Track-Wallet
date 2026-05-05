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

    private var validSize: CGFloat {
        max(1, size)
    }

    var body: some View {
        if let faviconURL = account.faviconURL {
            AsyncImage(url: faviconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: validSize, height: validSize)
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
            .font(.system(size: max(1, validSize * 0.45)))
            .foregroundColor(.white)
            .frame(width: validSize, height: validSize)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(account.color.toColor)
            )
    }
}

extension String {
    var toColor: Color {
        switch self.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "indigo": return .indigo
        case "teal": return .teal
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        case "brown": return .brown
        default:
            if self.hasPrefix("#") || self.count == 6 {
                return Color(hex: self)
            }
            return .blue
        }
    }

    static let namedColors = ["blue", "green", "orange", "red", "purple", "pink", "indigo", "teal", "yellow", "cyan", "mint", "brown"]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
