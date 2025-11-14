import SwiftUI
import UserNotifications

// MARK: - Configuration
private enum Config {
    static let folderName = "Seisen"
    static let notificationInterval: TimeInterval = 3600     // 1h
    static let maxWidth: CGFloat = 650

    /// URL d'un fichier de notes pour une catégorie donnée (dans iCloud Drive local)
    static func fileURL(for category: String) -> URL {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/\(folderName)", isDirectory: true)

        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base.appendingPathComponent("\(category).txt")
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var viewModel = SeisenViewModel()
    @State private var appear = false
    @State private var breathing = false
    @State private var themeFlash = false

    var body: some View {
        ZStack {
            backgroundLayer

            if !viewModel.isDarkMode { floatingParticles }

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 30)

                    categorySelector
                        .padding(.bottom, 18)

                    mainCard

                    footerQuote
                        .padding(.top, 24)
                }
                .frame(maxWidth: Config.maxWidth)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            viewModel.initialize()
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
            breathing = true
        }
    }
}

// MARK: - UI Layers
private extension ContentView {
    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: viewModel.isDarkMode
                    ? [Color(red: 0.05, green: 0.05, blue: 0.1),
                       Color(red: 0.1, green: 0.05, blue: 0.15)]
                    : [Color(red: 0.9, green: 0.98, blue: 0.98),
                       Color(red: 0.85, green: 0.95, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(viewModel.isDarkMode ? Color.purple.opacity(0.15) : Color.teal.opacity(0.2))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
                .scaleEffect(breathing ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathing)

            Circle()
                .fill(viewModel.isDarkMode ? Color.pink.opacity(0.12) : Color.cyan.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: 150, y: 200)
                .scaleEffect(breathing ? 0.9 : 1.1)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: breathing)
        }
    }

    var floatingParticles: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { _ in
                Circle()
                    .fill(Color.teal.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .blur(radius: 1)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
                    .animation(.linear(duration: Double.random(in: 15...25)).repeatForever(autoreverses: false), value: breathing)
            }
        }
        .opacity(0.4)
    }

    var header: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.isDarkMode ? "leaf.fill" : "sparkles")
                .font(.title2)
                .foregroundStyle(viewModel.isDarkMode ? Color.purple.opacity(0.8) : Color.teal)
                .scaleEffect(breathing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathing)

            Text(viewModel.isDarkMode ? "SEISEN ⚔️" : "SEISEN 🪷")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(
                    viewModel.isDarkMode
                    ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.teal, .cyan], startPoint: .leading, endPoint: .trailing)
                )
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .shadow(color: viewModel.isDarkMode ? Color.purple.opacity(0.3) : Color.teal.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(viewModel.isDarkMode ? Color.purple.opacity(0.3) : Color.teal.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: Category Selector
    var categorySelector: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.categories, id: \.self) { category in
                Button {
                    viewModel.changeCategory(to: category)
                } label: {
                    Text(displayName(for: category))
                        .font(.system(.caption, design: .rounded).bold())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.currentCategory == category
                                      ? Color.teal.opacity(0.7)
                                      : Color.white.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.teal.opacity(0.8),
                                        lineWidth: viewModel.currentCategory == category ? 2 : 1)
                        )
                        .foregroundColor(viewModel.currentCategory == category ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
    }

    func displayName(for category: String) -> String {
        switch category {
        case "sensei_notes": return "Sensei"
        case "samurai":      return "Samurai"
        case "zen":          return "Zen"
        case "42":           return "42"
        case "life":         return "Vie"
        case "custom":       return "Perso"
        default:             return category.capitalized
        }
    }

    // MARK: Main Card
    var mainCard: some View {
        VStack(spacing: 28) {
            currentNoteDisplay
            newNoteButton
            themeToggle
            dividerLine
            addNoteSection
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .shadow(color: viewModel.isDarkMode ? Color.purple.opacity(0.4) : Color.teal.opacity(0.3), radius: 40, x: 0, y: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(.white.opacity(0.4), lineWidth: 1)
        )
    }

    var currentNoteDisplay: some View {
        VStack(spacing: 16) {
            Text(viewModel.currentNote)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    viewModel.isDarkMode
                    ? LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.teal, .cyan, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .lineLimit(nil)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 30)
                .padding(.vertical, 35)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(viewModel.isDarkMode ? Color.purple.opacity(0.05) : Color.teal.opacity(0.05))
                        .blur(radius: 22)
                )
                .opacity(appear ? 1 : 0)
                .scaleEffect(appear ? 1 : 0.97)
                .animation(.easeOut(duration: 0.4), value: appear)

            Rectangle()
                .fill(
                    LinearGradient(colors: viewModel.isDarkMode ? [.purple, .pink] : [.teal, .cyan],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 120, height: 4)
                .cornerRadius(2)
        }
    }

    var newNoteButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) { appear = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                viewModel.loadRandomNote()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appear = true }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "figure.mind.and.body")
                    .font(.title3)
                    .scaleEffect(breathing ? 1.1 : 1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathing)
                Text("Nouvelle pensée")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Image(systemName: "bolt.fill")
                    .font(.body)
            }
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .background(
            LinearGradient(
                colors: viewModel.isDarkMode ? [Color.purple, Color.pink] : [Color.teal, Color.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: viewModel.isDarkMode ? Color.purple.opacity(0.5) : Color.teal.opacity(0.4), radius: 15, x: 0, y: 8)
        .scaleEffect(breathing ? 1.01 : 0.99)
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: breathing)
    }

    var themeToggle: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                viewModel.toggleTheme()
                themeFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) { themeFlash = false }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                    .font(.body)
                Text(viewModel.isDarkMode ? "Mode Samurai" : "Mode Zen")
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .foregroundColor(viewModel.isDarkMode ? Color.purple.opacity(0.9) : Color.teal)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(viewModel.isDarkMode ? Color.gray.opacity(0.2) : Color.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(viewModel.isDarkMode ? Color.purple.opacity(0.3) : Color.teal.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(themeFlash ? 1.05 : 1)
        .shadow(color: viewModel.isDarkMode ? Color.purple.opacity(0.2) : Color.teal.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    var dividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, viewModel.isDarkMode ? Color.purple.opacity(0.3) : Color.teal.opacity(0.4), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    var addNoteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("✍️ Ajouter une pensée")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(viewModel.isDarkMode ? .white.opacity(0.9) : .primary)

            HStack(spacing: 12) {
                TextField("Ta pensée…", text: $viewModel.newNoteText)
                    .font(.system(.body, design: .rounded))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.isDarkMode ? Color.gray.opacity(0.2) : Color.white.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.isDarkMode ? Color.purple.opacity(0.3) : Color.teal.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(viewModel.isDarkMode ? .white : .primary)
                    .onSubmit {
                        if !viewModel.newNoteText.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.addNote()
                        }
                    }

                Button {
                    viewModel.addNote()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.body.weight(.semibold))
                        Text("Ajouter").font(.system(.body, design: .rounded).weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        LinearGradient(
                            colors: viewModel.isDarkMode ? [Color.purple, Color.pink] : [Color.teal, Color.cyan],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: viewModel.isDarkMode ? Color.purple.opacity(0.4) : Color.teal.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(viewModel.newNoteText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(viewModel.newNoteText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
    }

    var footerQuote: some View {
        Text(viewModel.isDarkMode ? "\"Le guerrier intérieur ne dort jamais\"" : "\"La sagesse vient du calme intérieur\"")
            .font(.system(.footnote, design: .rounded))
            .italic()
            .foregroundColor(viewModel.isDarkMode ? Color.purple.opacity(0.5) : Color.teal.opacity(0.6))
    }
}

// MARK: - ViewModel
@MainActor
class SeisenViewModel: ObservableObject {
    @Published var currentNote = "Chargement…"
    @Published var newNoteText = ""
    @Published var isDarkMode = false
    @Published var currentCategory = "sensei_notes"

    let categories = ["sensei_notes", "samurai", "zen", "42", "life", "custom"]

    private var notificationTimer: Timer?

    func initialize() {
        FileManager.ensureCategoryFilesExist()
        loadCategory(currentCategory)
        NotificationManager.requestPermission()
        startNotificationTimer()
        print("📂 Notes base folder:", Config.fileURL(for: currentCategory).deletingLastPathComponent().path)
    }

    func loadCategory(_ category: String) {
        let path = Config.fileURL(for: category).path
        seisen_load_notes(path)
        loadRandomNote()
    }

    func changeCategory(to category: String) {
        currentCategory = category
        loadCategory(category)
    }

    func loadRandomNote() {
        currentNote = String(cString: seisen_get_note())
    }

    func addNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        FileManager.appendNote(trimmed, category: currentCategory)
        loadCategory(currentCategory)
        newNoteText = ""
    }

    func toggleTheme() { isDarkMode.toggle() }

    private func startNotificationTimer() {
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: Config.notificationInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                NotificationManager.sendZenNotification(self.currentNote)
            }
        }
    }

    deinit { notificationTimer?.invalidate() }
}

// MARK: - File Helpers
extension FileManager {
    /// Crée tous les fichiers de catégories s’ils n’existent pas
    static func ensureCategoryFilesExist() {
        let samples: [String: String] = [
            "sensei_notes": "Respire profondément.\nContinue.\nTu vas réussir.",
            "samurai": "La maîtrise vient de la discipline.\nAvance même blessé.\nLe doute est l'ennemi du sabre.",
            "zen": "Respire.\nReviens au présent.\nLe calme est une force.",
            "42": "Lis le man.\nApprivoise la mémoire.\nLe code vrai est humble.",
            "life": "Bois de l'eau.\nAppelle quelqu’un que tu aimes.\nRange ton esprit.",
            "custom": "Écris ta propre voie."
        ]

        for (name, content) in samples {
            let url = Config.fileURL(for: name)
            if !FileManager.default.fileExists(atPath: url.path) {
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    /// Ajoute une note à la catégorie courante
    static func appendNote(_ text: String, category: String) {
        let url = Config.fileURL(for: category)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? "".write(to: url, atomically: true, encoding: .utf8)
        }
        guard let file = try? FileHandle(forWritingTo: url) else { return }
        defer { file.closeFile() }
        file.seekToEndOfFile()
        file.write(("\n\(text)").data(using: .utf8)!)
    }
}

// MARK: - Notifications
enum NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { print("❌ Notification permission error:", error) }
        }
    }

    static func sendZenNotification(_ text: String) {
        let content = UNMutableNotificationContent()
        content.title = "🧘 Message du Sensei"
        content.body = text
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { error in
            if let error { print("❌ Notification error:", error) }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

