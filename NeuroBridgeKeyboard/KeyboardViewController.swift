// Copyright (c) 2026 Alden Lougee. All rights reserved.
// Proprietary and confidential. Unauthorized copying, modification,
// distribution, or derivative use is prohibited.

import UIKit
import SwiftUI

// MARK: - Cross-platform ToneLayer colors

extension Color {
    static let toneLayerBlue = Color(red: 0.145, green: 0.388, blue: 0.922)
    static let brandTeal = Color(red: 0.145, green: 0.388, blue: 0.922)
    static let toneLayerBlueSoft = Color(red: 0.859, green: 0.918, blue: 0.996)
    static let clarityGreen = Color(red: 0.047, green: 0.525, blue: 0.318)
    static let clarityPurple = Color(red: 0.435, green: 0.310, blue: 0.745)
    static let clarityPurpleSoft = Color(red: 0.941, green: 0.922, blue: 0.988)

    // Apple-keyboard inspired neutrals: high contrast, low visual noise.
    static let appleKeyboardBackground = Color(red: 0.859, green: 0.918, blue: 0.996)
    static let appleKeyboardKey = Color.white
    static let appleKeyboardSpecialKey = Color(red: 0.725, green: 0.808, blue: 0.949)
    static let appleKeyboardText = Color(red: 0.055, green: 0.065, blue: 0.080)
}

private enum KeyboardMode: String, CaseIterable, Identifiable {
    case toneLayer = "ToneLayer"
    case clarity = "Clarity"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .toneLayer: return .toneLayerBlue
        case .clarity: return .clarityPurple
        }
    }

    var softBackground: Color {
        switch self {
        case .toneLayer: return .toneLayerBlueSoft
        case .clarity: return .clarityPurpleSoft
        }
    }

    var specialKey: Color {
        switch self {
        case .toneLayer: return Color(red: 0.725, green: 0.808, blue: 0.949)
        case .clarity: return Color(red: 0.812, green: 0.765, blue: 0.941)
        }
    }

    var directionLabel: String {
        switch self {
        case .toneLayer: return "ND -> NT"
        case .clarity: return "NT -> ND"
        }
    }

    var previewHelp: String {
        switch self {
        case .toneLayer:
            return "ND -> NT: choose how you want the message to land."
        case .clarity:
            return "NT -> ND: make wording explicit and easier to parse."
        }
    }
}

// MARK: - Principal class

class KeyboardViewController: UIInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let host = UIHostingController(rootView: KeyboardView(inputVC: self))
        host.view.backgroundColor = .clear
        host.view.clipsToBounds = true
        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)
        host.view.translatesAutoresizingMaskIntoConstraints = false

        // Pin to all edges with priority below 1000 so we never fight the
        // system-driven inputView height (which can change with rotation, etc).
        // Width must stay required; otherwise iOS can let the hosting view keep
        // a wider intrinsic size and clip the keyboard off the left edge.
        let top = host.view.topAnchor.constraint(equalTo: view.topAnchor)
        let bot = host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let lead = host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trail = host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        [top, bot].forEach { $0.priority = .defaultHigh }
        [lead, trail].forEach { $0.priority = .required }
        NSLayoutConstraint.activate([top, bot, lead, trail])
    }
}

// MARK: - SwiftUI keyboard view

struct KeyboardView: View {
    let inputVC: UIInputViewController

    private let appGroupID = "group.com.alden.ndclarity"
    private var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    @State private var profile      = "Autism"
    @State private var level        = "Medium"
    @State private var keyboardMode = KeyboardMode.toneLayer
    @State private var isRewriting  = false
    @State private var status       = ""
    @State private var explanation  = ""
    @State private var showExpl     = true
    @State private var spiralEnabled = true

    // Spiral card state
    @State private var showSpiral   = false
    @State private var spiralNT     = ""
    @State private var spiralGrammar = ""
    @State private var spiralOriginal = ""
    @State private var spiralOriginalCount = 0
    @State private var isShifted = false
    @State private var isNumbers = false
    @State private var lastRewriteStyle = "Rewrite"
    @State private var keyboardTypedText = ""

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            mainPanel
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .background(keyboardMode.softBackground)
        .preferredColorScheme(.light)
        .onAppear { loadSettings() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(keyboardMode.accent)
                .font(.system(size: 15))
            VStack(alignment: .leading, spacing: 1) {
                Text(keyboardMode.rawValue)
                    .font(.system(size: 11, weight: .bold))
                Text(profile)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 1) {
                Text(keyboardMode.directionLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(keyboardMode.accent)
                    .lineLimit(1)
                Text(levelKeyTitle(level))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button { inputVC.advanceToNextInputMode() } label: {
                Image(systemName: "globe")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Main panel

    private var mainPanel: some View {
        VStack(spacing: 10) {
            modeSelector
                .padding(.horizontal, 8)

            // Rewrite intensity selector
            HStack(spacing: 6) {
                ForEach(["Light", "Medium", "Strong"], id: \.self) { l in
                    Button {
                        level = l
                        defaults?.set(l, forKey: "rewriteLevel")
                    } label: {
                        Text(levelKeyTitle(l))
                            .font(.system(size: 14, weight: level == l ? .bold : .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(level == l ? keyboardMode.accent : keyboardMode.specialKey.opacity(0.78))
                            .foregroundStyle(level == l ? Color.white : Color.appleKeyboardText)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(l) rewrite level")
                }
            }
            .padding(.horizontal, 8)

            if !status.isEmpty {
                Text(status)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            rewriteWindow
                .padding(.horizontal, 6)

            rewriteActionRow
                .padding(.horizontal, 4)

            qwertyKeyboard
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
        }
        .padding(.top, 10)
    }

    private var modeSelector: some View {
        HStack(spacing: 6) {
            ForEach(KeyboardMode.allCases) { mode in
                Button {
                    keyboardMode = mode
                    defaults?.set(mode.rawValue, forKey: "keyboardMode")
                    defaults?.synchronize()
                    lastRewriteStyle = mode == .toneLayer ? "Rewrite" : "Clarity"
                } label: {
                    VStack(spacing: 1) {
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: keyboardMode == mode ? .bold : .semibold))
                            .lineLimit(1)
                        Text(mode.directionLabel)
                            .font(.system(size: 9, weight: .semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(keyboardMode == mode ? mode.accent : Color.appleKeyboardKey.opacity(0.9))
                    .foregroundStyle(keyboardMode == mode ? Color.white : Color.appleKeyboardText)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rewriteActionRow: some View {
        HStack(spacing: 5) {
            rewriteChip("Clarify", systemImage: "sparkles") { rewrite(style: "Clarify") }
            rewriteChip("Brief", systemImage: nil) { rewrite(style: "Shorter") }
            rewriteChip("Soften", systemImage: nil) { rewrite(style: "Warmer") }
            rewriteChip("Direct", systemImage: nil) { rewrite(style: "Direct") }
        }
    }

    private var qwertyKeyboard: some View {
        VStack(spacing: 4) {
            if isNumbers {
                keyRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
                keyRow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""])
                HStack(spacing: 4) {
                    specialKey("ABC", width: 52) { isNumbers = false }
                    keyRow([".", ",", "?", "!", "'"], flexible: true)
                    specialKey("⌫", width: 52) { inputVC.textDocumentProxy.deleteBackward(); if !keyboardTypedText.isEmpty { keyboardTypedText.removeLast() } }
                }
            } else {
                keyRow(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"])
                keyRow(["a", "s", "d", "f", "g", "h", "j", "k", "l"]).padding(.horizontal, 18)
                HStack(spacing: 4) {
                    specialKey(isShifted ? "⇧" : "⇧", width: 42, highlighted: isShifted) { isShifted.toggle() }
                    keyRow(["z", "x", "c", "v", "b", "n", "m"], flexible: true)
                    specialKey("⌫", width: 42) { inputVC.textDocumentProxy.deleteBackward(); if !keyboardTypedText.isEmpty { keyboardTypedText.removeLast() } }
                }
            }

            HStack(spacing: 4) {
                specialKey(isNumbers ? "ABC" : "123", width: 48) { isNumbers.toggle() }
                specialKey("🌐", width: 42) { inputVC.advanceToNextInputMode() }
                Button { inputVC.textDocumentProxy.insertText(" "); keyboardTypedText += " " } label: {
                    Text("space")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.appleKeyboardKey)
                        .foregroundStyle(Color.appleKeyboardText)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                specialKey("return", width: 70) { inputVC.textDocumentProxy.insertText("\n"); keyboardTypedText += "\n" }
            }
        }
    }

    private func keyRow(_ keys: [String], flexible: Bool = false) -> some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                letterKey(key)
                    .if(flexible) { $0.frame(maxWidth: .infinity) }
            }
        }
    }

    private func letterKey(_ key: String) -> some View {
        Button {
            let output = isShifted ? key.uppercased() : key
            inputVC.textDocumentProxy.insertText(output)
            keyboardTypedText += output
            if isShifted { isShifted = false }
        } label: {
            Text(isShifted ? key.uppercased() : key)
                .font(.system(size: 21))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Color.appleKeyboardKey)
                .foregroundStyle(Color.appleKeyboardText)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: Color.black.opacity(0.22), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func specialKey(_ title: String, width: CGFloat, highlighted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: width, height: 38)
                .background(highlighted ? Color.appleKeyboardKey : keyboardMode.specialKey)
                .foregroundStyle(Color.appleKeyboardText)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func rewriteChip(_ title: String, systemImage: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isRewriting && title == "Rewrite" {
                    ProgressView().scaleEffect(0.6).tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 11))
                }
                Text(isRewriting ? "Working" : title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isRewriting ? keyboardMode.accent.opacity(0.55) : Color.appleKeyboardKey)
            .foregroundStyle(title == "Clarify" ? keyboardMode.accent : Color.appleKeyboardText)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .shadow(color: Color.black.opacity(0.16), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(isRewriting)
    }

    private var rewriteWindow: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(keyboardMode.accent)
                Text("\(keyboardMode.rawValue) preview")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.12, green: 0.15, blue: 0.18))
                Spacer()
                Text(lastRewriteStyle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            if showSpiral {
                Text("Pause check: this may land differently than intended. Choose As-is, Grammar, or NT.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else if !explanation.isEmpty && showExpl {
                Text(explanation)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text(keyboardMode.previewHelp)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(keyboardMode.accent.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Spiral card

    private var spiralCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("💚  Pause for a sec?")
                .font(.system(size: 13, weight: .bold))
            Text("Your text has some patterns that might land differently than you intend.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                chipButton("As-is", primary: false) {
                    spiralOriginal = ""
                    spiralOriginalCount = 0
                    showSpiral = false
                }
                chipButton("Grammar", primary: false) {
                    applySpiral(spiralGrammar.isEmpty ? spiralOriginal : spiralGrammar)
                }
                chipButton(keyboardMode == .toneLayer ? "NT" : "Clarity", primary: true) { applySpiral(spiralNT) }
            }
        }
        .padding(14)
        .background(keyboardMode.softBackground.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(keyboardMode.accent.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Explanation card

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("💡").font(.system(size: 13))
            Text(explanation)
                .font(.system(size: 11))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button { withAnimation { explanation = "" } } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(keyboardMode.accent)
                    .font(.system(size: 20))
            }
        }
        .padding(12)
        .background(keyboardMode.softBackground.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(keyboardMode.accent.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func chipButton(_ title: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(primary ? keyboardMode.accent : Color(.systemGray4))
                .foregroundStyle(primary ? Color.white : Color(red: 0.12, green: 0.15, blue: 0.18))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func levelKeyTitle(_ value: String) -> String {
        switch value {
        case "Light": return "L"
        case "Medium": return "M"
        case "Strong": return "S"
        default: return value
        }
    }

    // MARK: - Load settings

    private func loadSettings() {
        let p = defaults?.string(forKey: "selectedProfile") ?? "Autism"
        switch p {
        case "PTSD":
            profile = "PTSD / CPTSD"
        case "PTSD + ADHD":
            profile = "ADHD + PTSD"
        case "PTSD + Autism":
            profile = "Autism + PTSD"
        case "Mixed":
            profile = "Mixed / Not Sure"
        default:
            profile = p
        }

        let storedMode = defaults?.string(forKey: "keyboardMode") ?? KeyboardMode.toneLayer.rawValue
        keyboardMode = KeyboardMode(rawValue: storedMode) ?? .toneLayer

        let stored = defaults?.string(forKey: "rewriteLevel") ?? "Medium"
        level = ["Light", "Medium", "Strong"].contains(stored) ? stored : "Medium"

        spiralEnabled = defaults?.object(forKey: "spiralPauseEnabled") == nil
            ? true : (defaults?.bool(forKey: "spiralPauseEnabled") ?? true)
        showExpl = defaults?.object(forKey: "showExplanation") == nil
            ? true : (defaults?.bool(forKey: "showExplanation") ?? true)
    }

    // MARK: - Rewrite

    private func incrementMetric(_ key: String, by amount: Int = 1) {
        let fullKey = "metrics.\(key)"
        defaults?.set((defaults?.integer(forKey: fullKey) ?? 0) + amount, forKey: fullKey)
        defaults?.set(Date(), forKey: "metrics.lastUpdated")
    }

    private func rewrite(style: String = "Clarify") {
        let proxy = inputVC.textDocumentProxy

        // documentContextBeforeInput is capped by iOS to ~100–200 chars.
        // Prefer the full text written by the test box (UIKitTextView) to shared UserDefaults.
        // For other apps, fall back to the proxy (limited to what the host exposes).
        defaults?.synchronize()
        let before = proxy.documentContextBeforeInput ?? ""
        let after  = proxy.documentContextAfterInput  ?? ""
        let proxyText = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        let typedText = keyboardTypedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = typedText.isEmpty ? proxyText : typedText
        let totalToDelete = typedText.isEmpty ? (before.count + after.count) : typedText.count

        guard !full.isEmpty else { showStatus("Type some text first"); return }

        lastRewriteStyle = style
        incrementMetric("keyboard.\(keyboardMode.rawValue.lowercased()).rewrite.requested")
        incrementMetric("keyboard.\(keyboardMode.rawValue.lowercased()).rewrite.style.\(style)")
        if full.count >= 700 || full.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count >= 120 {
            incrementMetric("keyboard.longMessage.flagged")
        }
        showStatus("Sending \(full.count) chars…")
        isRewriting = true
        explanation = ""
        showSpiral  = false
        defaults?.set(true, forKey: "keyboardRewriteInProgress")
        defaults?.synchronize()

        Task {
            do {
                let result = try await callClaude(text: full, style: style)

                // Move to the end first. deleteBackward() only removes text before the cursor,
                // so replacing a pasted brain dump from the middle can otherwise leave one half
                // of the original untouched.
                await moveCursorToEnd(proxy: proxy, knownTextCount: full.count)

                // Chunk the deletion so the host app's IPC can keep up.
                // Tight 3000-call loops overwhelm UITextDocumentProxy and silently drop most.
                await deleteBackwardChunked(proxy: proxy, count: totalToDelete)

                await insertTextChunked(proxy: proxy, text: result.rewrite)
                await MainActor.run {
                    isRewriting = false

                    if spiralEnabled && result.isSpiraling {
                        spiralNT      = result.rewrite
                        spiralGrammar = result.grammarOnly
                        spiralOriginal = full
                        spiralOriginalCount = full.count
                    }
                }

                if spiralEnabled && result.isSpiraling {
                    await deleteBackwardChunked(proxy: proxy, count: result.rewrite.count)
                    await insertTextChunked(proxy: proxy, text: full)
                    await MainActor.run {
                        defaults?.set(full, forKey: "testBoxFullText")
                        defaults?.set(false, forKey: "keyboardRewriteInProgress")
                        defaults?.synchronize()
                        withAnimation { showSpiral = true }
                    }
                } else {
                    await MainActor.run {
                        keyboardTypedText = result.rewrite
                        defaults?.set(result.rewrite, forKey: "testBoxFullText")
                        defaults?.set(false, forKey: "keyboardRewriteInProgress")
                        defaults?.synchronize()
                        if showExpl {
                            let text = result.explanation.isEmpty
                                ? "Rewritten at \(level) level for \(keyboardMode.rawValue) / \(profile)."
                                : result.explanation
                            withAnimation { explanation = text }
                        }
                        incrementMetric("keyboard.\(keyboardMode.rawValue.lowercased()).rewrite.success")
                        showStatus("Rewritten ✓")
                        saveLog(original: full, result: result)
                    }
                }
            } catch {
                await MainActor.run {
                    incrementMetric("keyboard.\(keyboardMode.rawValue.lowercased()).rewrite.failed")
                    isRewriting = false
                    defaults?.set(false, forKey: "keyboardRewriteInProgress")
                    defaults?.synchronize()
                    showStatus(error.localizedDescription)
                }
            }
        }
    }

    private func deleteBackwardChunked(proxy: UITextDocumentProxy, count: Int) async {
        let chunkSize = 50
        var remaining = count
        while remaining > 0 {
            let thisChunk = min(chunkSize, remaining)
            await MainActor.run {
                for _ in 0..<thisChunk { proxy.deleteBackward() }
            }
            remaining -= thisChunk
            try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        }
    }

    private func moveCursorToEnd(proxy: UITextDocumentProxy, knownTextCount: Int) async {
        await MainActor.run {
            proxy.adjustTextPosition(byCharacterOffset: knownTextCount)
        }
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
    }

    private func insertTextChunked(proxy: UITextDocumentProxy, text: String) async {
        let chunkSize = 400
        var index = text.startIndex
        while index < text.endIndex {
            let next = text.index(index, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let chunk = String(text[index..<next])
            await MainActor.run {
                proxy.insertText(chunk)
            }
            index = next
            try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        }
    }

    private func applySpiral(_ text: String) {
        let proxy = inputVC.textDocumentProxy
        let before = proxy.documentContextBeforeInput ?? ""
        let deleteCount = spiralOriginalCount > 0 ? spiralOriginalCount : before.count
        defaults?.set(true, forKey: "keyboardRewriteInProgress")
        defaults?.synchronize()
        Task {
            await moveCursorToEnd(proxy: proxy, knownTextCount: deleteCount)
            await deleteBackwardChunked(proxy: proxy, count: deleteCount)
            await insertTextChunked(proxy: proxy, text: text)
            await MainActor.run {
                keyboardTypedText = text
                defaults?.set(text, forKey: "testBoxFullText")
                defaults?.set(false, forKey: "keyboardRewriteInProgress")
                defaults?.synchronize()
                spiralOriginal = ""
                spiralOriginalCount = 0
                withAnimation { showSpiral = false }
                showStatus("Applied ✓")
            }
        }
    }

    private func showStatus(_ msg: String) {
        status = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { status = "" }
    }

    // MARK: - Claude API

    struct ClaudeResult {
        let rewrite: String
        let explanation: String
        let distortions: [String]
        let grammarOnly: String
        var isSpiraling: Bool { !distortions.isEmpty }
    }

    private func callClaude(text: String, style: String = "Clarify") async throws -> ClaudeResult {
        guard let apiKey = defaults?.string(forKey: "claudeAPIKey"), !apiKey.isEmpty else {
            throw NBError.noKey
        }

        let system = buildSystem(style: style)
        let prompt = "Text:\n\(text)\n\nReply with ONLY valid JSON."

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(apiKey,           forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",     forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 90
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model":      "claude-haiku-4-5-20251001",
            "max_tokens": 8192,
            "system":     system,
            "messages":   [["role": "user", "content": prompt]],
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw NBError.apiFailed(0) }
        if http.statusCode != 200 {
            // Try to surface Claude's error message so user sees the real problem
            if let errJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = errJSON["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw NBError.apiMessage("\(http.statusCode): \(msg.prefix(120))")
            }
            throw NBError.apiFailed(http.statusCode)
        }
        guard let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first?["text"] as? String
        else { throw NBError.badResponse }

        // Try to parse JSON from Claude's response — strip markdown fences if present
        let cleaned = extractJSON(from: content)
        if let d = cleaned.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
            // Prefer paragraphs array (avoids JSON \n\n escaping issues); fall back to rewrite string
            let rewrite: String
            if let paras = parsed["paragraphs"] as? [String], !paras.isEmpty {
                rewrite = paras.joined(separator: "\n\n")
            } else if let r = parsed["rewrite"] as? String, !r.isEmpty {
                rewrite = r
            } else {
                rewrite = ""
            }
            if !rewrite.isEmpty {
                return ClaudeResult(
                    rewrite:      rewrite,
                    explanation:  parsed["explanation"]  as? String   ?? "",
                    distortions:  parsed["distortions"]  as? [String] ?? [],
                    grammarOnly:  parsed["grammar_only"] as? String   ?? ""
                )
            }
        }
        // Fallback: use plain content — but strip any obvious JSON noise
        return ClaudeResult(
            rewrite: cleaned.trimmingCharacters(in: .whitespacesAndNewlines),
            explanation: "", distortions: [], grammarOnly: ""
        )
    }

    /// Extracts JSON from a response that may be wrapped in ```json ... ``` or have
    /// extra text before/after. Returns the inner JSON object string, or the input unchanged.
    private func extractJSON(from raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip markdown fences
        if s.hasPrefix("```") {
            if let firstNL = s.firstIndex(of: "\n") {
                s = String(s[s.index(after: firstNL)...])
            }
            if s.hasSuffix("```") {
                s = String(s.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // If there's still extra text, grab the first { ... } block
        if let openIdx = s.firstIndex(of: "{"),
           let closeIdx = s.lastIndex(of: "}"),
           openIdx < closeIdx {
            return String(s[openIdx...closeIdx])
        }
        return s
    }

    private func buildSystem(style: String = "Clarify") -> String {
        let instruction = keyboardMode == .toneLayer
            ? toneLayerInstruction(level: level, profile: profile)
            : clarityInstruction(level: level, profile: profile)
        let adaptive    = adaptiveContext()
        let styleInstruction: String
        switch style {
        case "Shorter": styleInstruction = "Make the rewrite shorter. Remove repetition and extra context while preserving the actual point."
        case "Warmer": styleInstruction = "Make the rewrite warmer and more socially soft, without becoming fake or over-apologetic."
        case "Direct": styleInstruction = "Make the rewrite more direct, clear, and action-oriented without sounding harsh."
        case "Clarify": styleInstruction = "Make the message clearer, easier to read, and closer to the user’s intended meaning."
        default: styleInstruction = "Make a balanced clear rewrite."
        }
        if keyboardMode == .clarity {
            return """
            You are ToneLayer Clarity, a communication assistant for neurotypical senders who want their message to be easier for neurodivergent people to understand. Direction: NT-to-ND. Audience lens: \(profile). \(instruction) \(styleInstruction)\(adaptive)

            Rewrite the entire text so it is explicit, concrete, low-threat, and easy for a neurodivergent reader to parse. Identify hidden assumptions, vague phrasing, unclear urgency, implied expectations, accidental threat signals, and missing next steps. Do not diagnose the reader. Do not shame the sender. Preserve the sender's intended meaning while making the topic, timing, tone, and requested action clear.

            The "paragraphs" rewrite is the primary output. Do not shorten, flatten, or simplify the main rewrite to make room for grammar_only. Generate grammar_only after the main rewrite, and keep it secondary.

            This is a teaching tool. The explanation must teach how the original NT wording may land to an ND reader and why the rewrite is easier to understand.

            Always respond with ONLY valid JSON — no markdown, no code fences, no extra text.

            {
              "paragraphs": ["first paragraph as a plain string", "second paragraph as a plain string if needed"],
              "explanation": "REQUIRED: one sentence explaining what hidden assumption, vague wording, threat signal, or missing next step you addressed and why the rewrite is easier for ND readers.",
              "distortions": [],
              "grammar_only": "secondary option: grammar-fixed version of the full original that preserves the sender's structure and meaning but fixes grammar, spelling, punctuation, and obvious typos."
            }
            """
        }
        return """
        You are ToneLayer, a communication assistant that translates ND communication into NT-readable communication for a \(profile) user. Direction: ND-to-NT. \(instruction) \(styleInstruction)\(adaptive)

        Rewrite the entire text the user provided from ND style into NT style. Do not stop halfway, do not summarize only the beginning, and do not omit later points just because the text is long or messy. Preserve the user's intended message, requests, constraints, and necessary context from the whole original, but translate the structure, order, tone, and phrasing into what an NT reader would naturally expect.

        The "paragraphs" rewrite is the primary output. Do not shorten, flatten, or simplify the main rewrite to make room for grammar_only. Generate grammar_only after the main rewrite, and keep it secondary.

        This is a teaching tool. The explanation must teach — don't just say what changed, say WHY that change makes the text land better with NT readers. Help the user recognise their own patterns over time.

        Always respond with ONLY valid JSON — no markdown, no code fences, no extra text.

        {
          "paragraphs": ["first paragraph as a plain string", "second paragraph as a plain string", "third paragraph if needed"],
          "explanation": "REQUIRED: one sentence explaining what ND pattern you addressed and why the change makes it more NT-legible (e.g. 'Moved the main ask to the first sentence — NT readers need to know the purpose before the context, not after.').",
          "distortions": ["any cognitive distortions found, e.g. catastrophizing, mind-reading — empty array if none"],
          "grammar_only": "secondary option: grammar-fixed version of the full original that keeps the user's ND structure and meaning but fixes grammar, spelling, punctuation, and obvious typos. Keep this secondary to paragraphs."
        }
        """
    }

    private func adaptiveContext() -> String {
        let patterns = LogStore.shared.topPatterns()
        guard !patterns.isEmpty else { return "" }
        let list = patterns.map { "\($0.pattern) (\($0.count)×)" }.joined(separator: ", ")
        return "\n\nThis user's recurring patterns: \(list). Be especially attentive to these."
    }

    // MARK: - Level instructions (Light / Medium / Strong = how far the rewrite goes)

    private func toneLayerInstruction(level: String, profile: String) -> String {
        switch profile {

        case "ADHD":
            switch level {
            case "Light":
                return "Make minimal changes. Fix typos and grammar. If the main point is completely buried, move it to the first sentence. Preserve all content and the user's voice. This is a light polish — do not cut or restructure."
            case "Medium":
                return "Restructure from ND flow into NT readability. Move the main point to the first sentence. Group related ideas into short paragraphs — each paragraph covers one topic. Cut obvious repetition but keep all distinct ideas and the user's voice intact. The rewrite MUST have multiple paragraphs separated by blank lines. NT readers should be able to follow without effort."
            default: // Strong
                return "Make a strong ND-to-NT rewrite for ADHD communication. This should read almost like a clear, practical NT message: concise, direct, organized, emotionally regulated, and low-friction for the reader. First sentence states the purpose. Remove spirals, side quests, metaphors, repeated urgency, internal noise, and process-heavy explanation. Keep only the necessary meaning, request, constraints, and useful context. If the text is asking for help, name the actual support need in one clean sentence."
            }

        case "Autism":
            switch level {
            case "Light":
                return "Make a light ND-to-NT rewrite. Fix typos. Add a brief greeting or sign-off only if completely absent. Keep all content and voice intact."
            case "Medium":
                return "Make a medium ND-to-NT rewrite. Add appropriate social warmth — a genuine greeting, warm transitions, polite closing. Decode any implied meaning and state it directly. Keep all literal content. NT readers should feel connected, not just informed."
            default: // Strong
                return "Make a strong ND-to-NT rewrite using NT social norms. Add natural social flow — appropriate opening, warmth throughout, clear closing. Remove overly blunt phrasing where it would land poorly. Preserve all the user's meaning. Should read as something an NT person would naturally write to build or maintain a relationship."
            }

        case "PTSD / CPTSD":
            switch level {
            case "Light":
                return "Make a light ND-to-NT rewrite. Soften the most reactive or escalating phrases only. Keep all content and the user's voice intact."
            case "Medium":
                return "Make a medium ND-to-NT rewrite. Remove over-justification, excessive apology, and defensive language. Rewrite hedging sentences to be direct. Calm tone throughout. NT readers should feel a steady, confident person wrote this."
            default: // Strong
                return "Make a strong ND-to-NT rewrite into calm, grounded communication. Remove all defensive language, over-explanation, and anticipatory apology. Write with quiet confidence — what a calm, clear-headed NT person would write with the same message. No escalating language, no hedging."
            }

        case "Autism + PTSD", "PTSD + Autism":
            switch level {
            case "Light":
                return "Make a light ND-to-NT rewrite. Soften the most reactive phrases and add a greeting if absent. Minimal changes otherwise."
            case "Medium":
                return "Make a medium ND-to-NT rewrite. Remove over-justification and add social warmth. Direct but kind. Cut defensive hedging while adding genuine warmth and connection."
            default: // Strong
                return "Make a strong ND-to-NT rewrite: warm, direct, calm, no over-justification, no idioms. What a warm, grounded NT person would write with the same message."
            }

        case "ADHD + PTSD", "PTSD + ADHD":
            switch level {
            case "Light":
                return "Make a light ND-to-NT rewrite. Soften the most reactive phrasing and move the main point closer to the start if buried. Minimal changes otherwise."
            case "Medium":
                return "Make a medium ND-to-NT rewrite. Lead with the main point. Cut the worst tangents. Remove defensive over-explanation. Calmer and more focused."
            default: // Strong
                return "Make a strong ND-to-NT rewrite for PTSD + ADHD communication. This should be concise, calm, direct, and almost businesslike. Lead with the point. Remove spirals, defensive language, repeated urgency, over-explanation, and internal processing. Keep the valid need and any necessary context. If the text is asking for help, name the support need in one clean sentence."
            }

        case "Mixed / Not Sure", "Mixed":
            switch level {
            case "Light":
                return "Make a light mixed-needs rewrite. Keep the user's voice, but move the main point earlier, define vague timing, and reduce the most confusing or emotionally loaded phrasing."
            case "Medium":
                return "Make a mixed-needs rewrite for overlapping ADHD, autistic, PTSD/CPTSD, and anxiety-related communication needs. Put the main point first. Reduce working-memory load. Make implied meaning explicit. Lower threat signals. Define timing and expectations. End with one clear next step."
            default:
                return "Make a strong mixed-needs rewrite. This should be concise, explicit, calm, low-threat, easy to act on, and socially clear. Remove side quests, buried asks, vague hints, defensive wording, repeated urgency, and unclear timing. Preserve the user's meaning and end with one obvious next step."
            }

        default:
            switch level {
            case "Light":  return "Make a light ND-to-NT rewrite. Fix typos and grammar only. Keep all content and voice intact."
            case "Medium": return "Restructure ND communication into NT-readable clarity. Main point first. Cut obvious repetition. Keep the user's voice and all distinct substance."
            default:       return "Fully translate ND communication for NT readers. Clear, direct, no unnecessary content. What an NT person would naturally write with the same intent, while preserving the whole message."
            }
        }
    }

    private func clarityInstruction(level: String, profile: String) -> String {
        let profileInstruction: String
        switch profile {
        case "ADHD":
            profileInstruction = "For ADHD, reduce working-memory load, put the priority first, make the next action obvious, define timing, and avoid burying the ask in context."
        case "Autism":
            profileInstruction = "For Autism, make meaning literal, remove social subtext, define expectations directly, and avoid vague phrases like soon, later, we should talk, or whatever works unless you define them."
        case "PTSD / CPTSD":
            profileInstruction = "For PTSD/CPTSD, lower threat signals, add reassurance when appropriate, avoid vague warnings, avoid criticism without context, and make the emotional stakes clear."
        case "ADHD + PTSD", "PTSD + ADHD":
            profileInstruction = "For ADHD + PTSD, lead with reassurance and the main point, define urgency, reduce working-memory load, remove threat signals, and end with one concrete next step."
        case "Autism + PTSD", "PTSD + Autism":
            profileInstruction = "For Autism + PTSD, use literal wording, reduce social subtext, lower threat signals, clarify expectations, and separate facts from feelings or requests."
        case "Mixed / Not Sure", "Mixed", "General ND":
            profileInstruction = "For Mixed / Not Sure, assume overlapping ADHD, autistic, PTSD/CPTSD, and anxiety-related communication needs. Make the main point obvious, reduce working-memory load, make implied meaning explicit, lower threat signals, and end with one clear next step."
        default:
            profileInstruction = "Use a broad neurodivergent-accessibility lens: remove ambiguity, name urgency, make the ask explicit, add necessary context, and give a concrete next step."
        }

        let intensityInstruction: String
        switch level {
        case "Light":
            intensityInstruction = "Make minimal Clarity changes. Keep the sender's voice, but define vague timing, add missing context, and make any hidden ask explicit."
        case "Medium":
            intensityInstruction = "Make a medium Clarity rewrite. Put the topic and intent first, name urgency, remove social hints, add reassurance if useful, and end with the requested action."
        default:
            intensityInstruction = "Make a strong Clarity rewrite. Fully translate indirect NT wording into explicit, calm, concrete ND-accessible wording with low threat, clear expectations, defined timing, and one obvious next step."
        }

        return "\(profileInstruction) \(intensityInstruction)"
    }

    // MARK: - Log

    private func saveLog(original: String, result: ClaudeResult) {
        let entry = RewriteEntry(
            id: UUID(), timestamp: Date(),
            profile: profile, mode: level,
            originalText: original, rewrittenText: result.rewrite,
            explanation: result.explanation,
            distortions: result.distortions, spiraling: result.isSpiraling
        )
        DispatchQueue.global(qos: .background).async { LogStore.shared.append(entry) }
    }
}

// MARK: - Errors

enum NBError: LocalizedError {
    case noKey
    case apiFailed(Int)
    case apiMessage(String)
    case badResponse
    var errorDescription: String? {
        switch self {
        case .noKey:                return "No API key — add it in the ToneLayer app"
        case .apiFailed(let code):  return "API failed (HTTP \(code))"
        case .apiMessage(let s):    return s
        case .badResponse:          return "Unexpected API response"
        }
    }
}

// MARK: - Shared log model (must match ContentView.swift)

struct RewriteEntry: Codable {
    let id: UUID
    let timestamp: Date
    let profile: String
    let mode: String
    let originalText: String
    let rewrittenText: String
    let explanation: String
    let distortions: [String]
    let spiraling: Bool
}

final class LogStore {
    static let shared = LogStore()
    private let appGroupID = "group.com.alden.ndclarity"
    private let fileName   = "rewrite_log.json"

    private var logURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    func load() -> [RewriteEntry] {
        guard let url = logURL,
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([RewriteEntry].self, from: data)
        else { return [] }
        return entries
    }

    func append(_ entry: RewriteEntry) {
        var entries = load()
        entries.append(entry)
        if entries.count > 500 { entries = Array(entries.suffix(500)) }
        guard let url = logURL,
              let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func topPatterns(limit: Int = 40) -> [(pattern: String, count: Int)] {
        let recent = Array(load().suffix(limit))
        let all = recent.flatMap { $0.distortions }.filter { !$0.isEmpty }
        return Dictionary(grouping: all, by: { $0 })
            .mapValues { $0.count }
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { (pattern: $0.key, count: $0.value) }
    }
}


private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
