//
//  Color+Extension.swift
//  mailmeil
//
//  Created by 고재현 on 4/12/25.
//

import SwiftUI

extension Color {
    static func fromName(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        case "gray": return .gray
        case "teal": return .teal
        case "cyan": return .cyan
        default: return .black
        }
    }
}
