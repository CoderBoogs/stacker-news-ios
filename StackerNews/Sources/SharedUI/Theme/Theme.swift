import SwiftUI

struct AppTheme {
    static let shared = AppTheme()
    
    let snYellow = Color(hue: 56/360, saturation: 1.0, brightness: 0.6)
    let snYellowDark = Color(hue: 51/360, saturation: 1.0, brightness: 0.55)
    let bitcoinOrange = Color(hue: 25/360, saturation: 1.0, brightness: 0.5)
    
    let darkBackground = Color(red: 0.07, green: 0.07, blue: 0.07)
    let darkCard = Color(red: 0.12, green: 0.12, blue: 0.12)
    let darkBorder = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    let lightBackground = Color.white
    let lightCard = Color.white
    let lightBorder = Color.gray.opacity(0.2)
    
    let green = Color.green
    let red = Color.red
    let blue = Color.blue
    
    func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }
    
    func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkCard : lightCard
    }
    
    func borderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBorder : lightBorder
    }
    
    func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
}

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme = .dark
    
    static let shared = ThemeManager()
    
    private init() {
        loadTheme()
    }
    
    func toggle() {
        colorScheme = colorScheme == .dark ? .light : .dark
        saveTheme()
    }
    
    private func loadTheme() {
        if let saved = UserDefaults.standard.string(forKey: "theme") {
            colorScheme = saved == "dark" ? .dark : .light
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(colorScheme == .dark ? "dark" : "light", forKey: "theme")
    }
}

extension View {
    func themedBackground() -> some View {
        self.modifier(ThemedBackgroundModifier())
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.shared.background(for: colorScheme))
    }
}

struct SNLogoText: View {
    var body: some View {
        Text("SN")
            .font(.system(size: 18, weight: .black, design: .default))
            .italic()
            .tracking(-2)
            .foregroundColor(.black)
    }
}

struct SNLogo: View {
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.shared.snYellow)
                .frame(width: size, height: size)
            
            SNLogoText()
        }
    }
}
