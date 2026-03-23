import SwiftUI

extension Color {
    // Carbon & Ember Theme Colors
    static let carbonBackground = Color(red: 0.051, green: 0.051, blue: 0.059) // #0D0D0F
    static let charcoal = Color(red: 0.102, green: 0.102, blue: 0.122) // #1A1A1F
    static let border = Color(red: 0.173, green: 0.173, blue: 0.208) // #2C2C35
    static let ember = Color(red: 0.957, green: 0.392, blue: 0.165) // #F4642A
    static let amber = Color(red: 0.969, green: 0.639, blue: 0.145) // #F7A325
    static let text = Color(red: 0.941, green: 0.937, blue: 0.914) // #F0EFE9
    static let muted = Color(red: 0.545, green: 0.545, blue: 0.604) // #8B8B9A
    static let win = Color(red: 0.239, green: 0.863, blue: 0.518) // #3DDC84
    static let loss = Color(red: 1.000, green: 0.278, blue: 0.341) // #FF4757
    
    // Legacy aliases for backward compatibility
    static let subtleText = muted
}

extension Font {
    static let headline = Font.system(size: 22, weight: .bold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
}
