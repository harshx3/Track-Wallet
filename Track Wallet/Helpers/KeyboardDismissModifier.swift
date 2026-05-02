//
//  KeyboardDismissModifier.swift
//  Track Wallet
//
//  Created by Harsh Makwana on 4/27/26.
//

import SwiftUI

extension View {
    func hideKeyboardOnTap() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }

    func dismissKeyboardOnTap() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }
}
