//
//  CurrencyFormatter.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import Foundation
import SwiftUI

extension String {
    var iconDisplayName: String {
        switch self {
        case "dollarsign.circle.fill": return "Dollar"
        case "banknote.fill": return "Banknote"
        case "building.columns.fill": return "Bank"
        case "creditcard.fill": return "Credit Card"
        case "wallet.pass.fill": return "Wallet"
        case "chart.line.uptrend.xyaxis": return "Chart"
        case "briefcase.fill": return "Briefcase"
        case "bag.fill": return "Bag"
        case "folder.fill": return "Folder"
        case "cart.fill": return "Shopping"
        case "house.fill": return "Home"
        case "car.fill": return "Transport"
        case "fork.knife": return "Food"
        case "gamecontroller.fill": return "Gaming"
        case "gift.fill": return "Gifts"
        case "heart.fill": return "Health"
        case "music.note": return "Music"
        case "book.fill": return "Education"
        case "graduationcap.fill": return "Academic"
        case "airplane": return "Travel"
        case "cross.case.fill": return "Medical"
        case "sparkles": return "Entertainment"
        case "tshirt.fill": return "Clothing"
        case "cup.and.saucer.fill": return "Cafe"
        default: return self
        }
    }
}

private let sharedCurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    formatter.maximumFractionDigits = 2
    return formatter
}()

extension Decimal {
    var currencyFormatted: String {
        sharedCurrencyFormatter.string(from: self as NSDecimalNumber) ?? "\(Locale.current.currencySymbol ?? "$")0.00"
    }
}

extension Double {
    var currencyFormatted: String {
        sharedCurrencyFormatter.string(from: self as NSNumber) ?? "\(Locale.current.currencySymbol ?? "$")0.00"
    }
}
