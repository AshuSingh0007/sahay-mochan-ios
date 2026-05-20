import SwiftUI

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let a, r, g, b: UInt64
        switch sanitized.count {
        case 3:
            (a, r, g, b) = (255, (value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8:
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

enum MochanTheme {
    static let sageBackground = Color(hex: "#F1F7F3")
    static let sageSoft = Color(hex: "#D3E4D6")
    static let sage = Color(hex: "#6B9071")
    static let sageDark = Color(hex: "#3E4E42")
    static let purple = Color(hex: "#8B5CF6")
    static let purpleSoft = Color(hex: "#A78BFA")
    static let purpleMist = Color(hex: "#F5F3FF")
    static let mild = Color(hex: "#10B981")
    static let moderate = Color(hex: "#F59E0B")
    static let severe = Color(hex: "#EF4444")
    static let primaryGradient = LinearGradient(colors: [sage, purpleSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let purpleGradient = LinearGradient(colors: [purple, purpleSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct MochanCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.94))
            .cornerRadius(8)
            .shadow(color: MochanTheme.sageDark.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

struct MochanButtonModifier: ViewModifier {
    var disabled: Bool

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if disabled {
                    Color.gray.opacity(0.5)
                } else {
                    MochanTheme.primaryGradient
                }
            }
            .cornerRadius(8)
    }
}

extension View {
    func mochanCard() -> some View { modifier(MochanCardModifier()) }
    func mochanButton(disabled: Bool = false) -> some View { modifier(MochanButtonModifier(disabled: disabled)) }
}
