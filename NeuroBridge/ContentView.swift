// Copyright (c) 2026 Alden Lougee. All rights reserved.
// Proprietary and confidential. Unauthorized copying, modification,
// distribution, or derivative use is prohibited.

//
//  ContentView.swift
//  NeuroBridge NT Clarity
//

import SwiftUI
import UIKit

extension Color {
    static let brandVioletDark = Color(red: 0.04, green: 0.06, blue: 0.22)
    static let brandViolet = Color(red: 0.02, green: 0.23, blue: 0.98)
    static let brandGreen = Color(red: 0.06, green: 0.72, blue: 0.70)
    static let brandWhite = Color(red: 0.97, green: 0.98, blue: 0.98)
    static let brandVioletMist = Color(red: 0.93, green: 0.91, blue: 1.0)
    static let brandGreenMist = Color(red: 0.93, green: 0.98, blue: 0.98)
}

struct GlassCard: ViewModifier {
    var tint: Color = .brandVioletDark
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [Color.brandWhite.opacity(0.42), tint.opacity(0.18), Color.brandViolet.opacity(0.16), Color.brandGreen.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.brandWhite.opacity(0.78), tint.opacity(0.44), Color.brandViolet.opacity(0.36), Color.brandGreen.opacity(0.26)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: tint.opacity(0.10), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func glassCard(tint: Color = .brandVioletDark, cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCard(tint: tint, cornerRadius: cornerRadius))
    }
}

struct ContentView: View {
    @State private var apiKey = ""
    @State private var draft = ""
    @State private var audienceLens = "General ND"
    @State private var goal = "Make clearer"
    @State private var isRewriting = false
    @State private var status = ""
    @State private var clearerVersion = ""
    @State private var interpretationRisk = ""
    @State private var changeNotes = ""
    @State private var learningTakeaway = ""
    @State private var teachingExplanation = ""
    @State private var selectedResult = "Fix"
    @State private var showingOptions = false
    @State private var showTeaching = true
    @State private var exportURL: URL?
    @State private var activityItems: [Any] = []
    @State private var showingExportSheet = false

    private let apiKeyKey = "ntClarityClaudeAPIKey"
    private let showTeachingKey = "ntClarityShowTeaching"
    private let lenses = ["General ND", "ADHD", "Autism", "PTSD / CPTSD"]
    private let goals = ["Make clearer", "Reduce anxiety", "Make actionable"]
    private let resultTabs = ["Fix", "Tone", "Why", "Tip"]
    private let dailyTips: [(title: String, body: String)] = [
        (
            "A blocked call may not feel neutral",
            "For someone with ADHD, trauma history, or rejection sensitivity, being blocked or repeatedly sent to voicemail can feel like rejection before there is any explanation. A short text like \"I cannot talk now, but I will reply later\" is usually safer."
        ),
        (
            "Hinting creates extra work",
            "Many neurodivergent people communicate better when the request is explicit. Instead of hoping they infer the problem, name what you need, when you need it, and whether it is urgent."
        ),
        (
            "Short can sound angry",
            "A message like \"fine\" or \"whatever\" may land as punishment or shutdown. If you mean reassurance, say it plainly: \"We are okay. I just need a little time.\""
        ),
        (
            "Unclear urgency can trigger panic",
            "Messages like \"call me\" or \"we need to talk\" can create anxiety because the person has to guess the emotional stakes. Add context when you can."
        ),
        (
            "Autistic processing may need precision",
            "Concrete language is often easier than social shorthand. Saying exactly what changed, what you expect, and what is optional reduces confusion."
        ),
        (
            "PTSD can read threat quickly",
            "A nervous system shaped by trauma may detect danger before logic catches up. Calm wording, predictable timing, and clear reassurance can reduce escalation."
        ),
        (
            "Repair beats perfect wording",
            "If your message lands badly, explain your intention without blaming the person for reacting. Repair sounds like: \"I see how that came across. What I meant was...\""
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                dailyTipCard
                composerCard
                optionsCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
            if UserDefaults.standard.object(forKey: showTeachingKey) == nil {
                showTeaching = true
                UserDefaults.standard.set(true, forKey: showTeachingKey)
            } else {
                showTeaching = UserDefaults.standard.bool(forKey: showTeachingKey)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if !activityItems.isEmpty {
                ActivityView(activityItems: activityItems)
            } else if let exportURL {
                ActivityView(activityItems: [exportURL])
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            Image("NeuroBridgeLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("ND Clarity")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.brandVioletDark)

            Text("Translate unclear neurotypical messaging into communication that is easier for neurodivergent people to understand.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard(tint: .brandVioletDark)
    }

    private var dailyTipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("FYI of the day", systemImage: "sparkle.magnifyingglass")
                .font(.headline)
                .foregroundStyle(Color.brandGreen)

            Text(todayTip.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text(todayTip.body)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.22, green: 0.26, blue: 0.30))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(tint: .brandGreen, cornerRadius: 18)
    }

    private var todayTip: (title: String, body: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return dailyTips[(day - 1) % dailyTips.count]
    }

    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("Message Check", systemImage: "text.bubble")
                    .font(.title3.weight(.semibold))
                Spacer()
                if !draft.isEmpty {
                    Text("\(draft.count) chars")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Goal", selection: $goal) {
                ForEach(goals, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)

            ZStack(alignment: .topLeading) {
                UIKitTextView(text: $draft)
                    .frame(minHeight: 220, maxHeight: 360)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )

                if draft.isEmpty {
                    Text("Paste what you were going to say...")
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 10) {
                Button { pasteFromClipboard() } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { clearDraft() } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(draft.isEmpty)
            }

            Button(action: rewriteMessage) {
                HStack {
                    if isRewriting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isRewriting ? "Tuning…" : "Clarify")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(isRewriting || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.brandVioletDark.opacity(0.45) : Color.brandVioletDark)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isRewriting || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !status.isEmpty {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if showTeaching {
                Picker("Result", selection: $selectedResult) {
                    ForEach(resultTabs, id: \.self) { Text($0).font(.caption).lineLimit(1).minimumScaleFactor(0.85).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Text(resultWindowText)
                .font(.body)
                        .foregroundStyle(Color(red: 0.12, green: 0.15, blue: 0.18))
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .padding(14)
                        .background(Color.brandVioletMist.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .textSelection(.enabled)

            VStack(alignment: .leading, spacing: 8) {
                Label("Why", systemImage: "lightbulb")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandVioletDark)
                Text(teachingWindowText)
                    .font(.subheadline)
                        .foregroundStyle(Color(red: 0.12, green: 0.15, blue: 0.18))
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
            .padding(14)
            .background(Color.brandGreenMist)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if hasOutput {
                HStack(spacing: 10) {
                    Button { copySelectedResult() } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandVioletDark)

                    Button { replaceDraftWithResult() } label: {
                        Label("Replace Draft", systemImage: "arrow.uturn.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Text("Send to")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                Button { openEmail() } label: {
                    Label("Email", systemImage: "envelope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { openMessages() } label: {
                    Label("Message", systemImage: "message")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .disabled(!hasOutput)

            HStack(spacing: 10) {
                Button { exportTextFile(label: "Word") } label: {
                    Label("Word", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { exportTextFile(label: "Pages") } label: {
                    Label("Pages", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .disabled(!hasOutput)

            Button { shareSelectedResult() } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brandGreen)
            .disabled(!hasOutput)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(tint: .brandVioletDark)
    }

    private var optionsCard: some View {
        DisclosureGroup(isExpanded: $showingOptions) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Audience Lens", systemImage: "person.2")
                        .font(.headline)
                    Picker("Audience Lens", selection: $audienceLens) {
                        ForEach(lenses, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text("Default to General ND unless you know which lens is appropriate.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Teaching explanations", systemImage: "lightbulb")
                            .font(.headline)
                        Text("Show how the message may sound and what to learn for next time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $showTeaching)
                        .labelsHidden()
                        .onChange(of: showTeaching) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: showTeachingKey)
                            if !newValue { selectedResult = "Fix" }
                        }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("API Key", systemImage: "key.fill")
                        .font(.headline)
                    SecureField("sk-ant-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Save Key") {
                        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
                        status = "API key saved"
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.top, 12)
        } label: {
            HStack {
                Label("Options", systemImage: "slider.horizontal.3")
                    .font(.title3.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.down.circle.fill")
                    .foregroundStyle(Color.brandGreen)
            }
        }
        .padding(20)
        .glassCard(tint: .brandGreen)
    }

    private var hasOutput: Bool {
        !clearerVersion.isEmpty || !interpretationRisk.isEmpty || !changeNotes.isEmpty
    }

    private var selectedResultText: String {
        switch selectedResult {
        case "Tone": return interpretationRisk
        case "Why": return changeNotes
        case "Tip": return learningTakeaway
        default: return clearerVersion
        }
    }

    private var resultWindowText: String {
        guard hasOutput else {
            return "Your clearer version will appear here."
        }
        return selectedResultText.isEmpty ? "Your clearer version will appear here." : selectedResultText
    }

    private var teachingWindowText: String {
        guard showTeaching else {
            return "Teaching explanations are turned off in Options."
        }
        guard hasOutput else {
            return "After a rewrite, this explains how the message may land and why the wording changed."
        }
        var parts: [String] = []
        if !teachingExplanation.isEmpty {
            parts.append(teachingExplanation)
        }
        if !interpretationRisk.isEmpty {
            parts.append("How this may sound:\n\(interpretationRisk)")
        }
        if !changeNotes.isEmpty {
            parts.append("What changed:\n\(changeNotes)")
        }
        if !learningTakeaway.isEmpty {
            parts.append("Learn:\n\(learningTakeaway)")
        }
        if !parts.isEmpty {
            return parts.joined(separator: "\n\n")
        }
        return "No teaching note returned for this rewrite."
    }

    private func pasteFromClipboard() {
        guard let pasted = UIPasteboard.general.string, !pasted.isEmpty else {
            status = "Clipboard is empty"
            return
        }
        draft = pasted
        status = "Pasted \(pasted.count) characters"
    }

    private func clearDraft() {
        draft = ""
        clearerVersion = ""
        interpretationRisk = ""
        changeNotes = ""
        learningTakeaway = ""
        teachingExplanation = ""
        status = ""
    }

    private func copySelectedResult() {
        UIPasteboard.general.string = selectedResultText
        status = "Copied \(selectedResult)"
    }

    private func replaceDraftWithResult() {
        draft = clearerVersion
        status = "Draft replaced"
    }

    private func shareSelectedResult() {
        activityItems = [selectedResultText]
        exportURL = nil
        showingExportSheet = true
        status = "Choose where to share"
    }

    private func rewriteMessage() {
        let input = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        guard !apiKey.isEmpty else {
            status = "Add your Claude API key in Options first"
            return
        }

        isRewriting = true
        status = "Checking message..."
        selectedResult = "Fix"

        Task {
            do {
                let result = try await callClaude(text: input)
                await MainActor.run {
                    clearerVersion = result.clearerVersion
                    interpretationRisk = result.interpretationRisk
                    changeNotes = result.changeNotes
                    learningTakeaway = result.learningTakeaway
                    teachingExplanation = result.teachingExplanation
                    isRewriting = false
                    status = "Ready"
                }
            } catch {
                await MainActor.run {
                    isRewriting = false
                    status = error.localizedDescription
                }
            }
        }
    }

    private struct ClarityResult {
        let clearerVersion: String
        let interpretationRisk: String
        let changeNotes: String
        let learningTakeaway: String
        let teachingExplanation: String
    }

    private func callClaude(text: String) async throws -> ClarityResult {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 90
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 4096,
            "system": buildSystemPrompt(),
            "messages": [["role": "user", "content": "Message:\n\(text)\n\nReply with ONLY valid JSON."]],
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw ClarityError.apiFailed(0) }
        if http.statusCode != 200 {
            if let errJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = errJSON["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw ClarityError.apiMessage("\(http.statusCode): \(msg.prefix(120))")
            }
            throw ClarityError.apiFailed(http.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first?["text"] as? String
        else { throw ClarityError.badResponse }

        let cleaned = extractJSON(from: content)
        guard let parsedData = cleaned.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: parsedData) as? [String: Any]
        else {
            return ClarityResult(
                clearerVersion: cleaned.trimmingCharacters(in: .whitespacesAndNewlines),
                interpretationRisk: "",
                changeNotes: "",
                learningTakeaway: "",
                teachingExplanation: ""
            )
        }

        return ClarityResult(
            clearerVersion: parsed["clearer_version"] as? String ?? "",
            interpretationRisk: parsed["interpretation_risk"] as? String ?? "",
            changeNotes: parsed["change_notes"] as? String ?? "",
            learningTakeaway: parsed["learning_takeaway"] as? String ?? "",
            teachingExplanation: parsed["teaching_explanation"] as? String
                ?? parsed["explanation"] as? String
                ?? ""
        )
    }

    private func buildSystemPrompt() -> String {
        """
        You are ND Clarity, a communication assistant for neurotypical senders who want their message to be easier for neurodivergent people to understand.

        Audience lens: \(audienceLens)
        Goal: \(goal)

        Your job is to identify hidden assumptions, vague phrasing, unclear urgency, implied expectations, accidental threat signals, and missing next steps. Do not diagnose the recipient. Do not shame the sender. Be concise, practical, specific, and teach the sender one reusable communication principle.

        General ND: remove ambiguity, make the ask explicit, add necessary context, state urgency, and give a concrete next step.
        ADHD: reduce working-memory load, make priority and next action obvious, avoid buried asks and long multi-step wording.
        Autism: make meaning literal, remove social subtext, state expectations directly, avoid vague phrases like "soon", "later", "we should talk", or "whatever works" unless defined.
        PTSD / CPTSD: reduce threat signals, add reassurance when appropriate, avoid vague warnings, criticism without context, or power-heavy phrasing.

        Always respond with ONLY valid JSON:
        {
          "clearer_version": "the rewritten message the sender can use",
          "teaching_explanation": "REQUIRED: plain-language explanation of how the original wording may land to the reader and why the rewrite improves clarity",
          "interpretation_risk": "brief explanation of what the sender may sound like to an ND person and why it may be confusing, threatening, vague, or hard to act on",
          "change_notes": "brief explanation of what changed and why",
          "learning_takeaway": "one reusable rule the NT sender can remember next time, written plainly"
        }
        """
    }

    private func extractJSON(from raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            if let firstNL = s.firstIndex(of: "\n") {
                s = String(s[s.index(after: firstNL)...])
            }
            if s.hasSuffix("```") {
                s = String(s.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if let openIdx = s.firstIndex(of: "{"),
           let closeIdx = s.lastIndex(of: "}"),
           openIdx < closeIdx {
            return String(s[openIdx...closeIdx])
        }
        return s
    }

    private func openEmail() {
        let encodedBody = clearerVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:?body=\(encodedBody)") else { return }
        UIApplication.shared.open(url) { success in
            if !success {
                UIPasteboard.general.string = clearerVersion
                status = "Email unavailable. Copied instead."
            }
        }
    }

    private func openMessages() {
        let encodedBody = clearerVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "sms:&body=\(encodedBody)") else { return }
        UIApplication.shared.open(url) { success in
            if !success {
                UIPasteboard.general.string = clearerVersion
                status = "Messages unavailable. Copied instead."
            }
        }
    }

    private func exportTextFile(label: String) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ND-Clarity-\(label).txt")
        do {
            try clearerVersion.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            activityItems = [url]
            showingExportSheet = true
            status = "Choose \(label) from the share sheet"
        } catch {
            UIPasteboard.general.string = clearerVersion
            status = "Export failed. Copied instead."
        }
    }
}

enum ClarityError: LocalizedError {
    case apiFailed(Int)
    case apiMessage(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .apiFailed(let code): return "API failed (HTTP \(code))"
        case .apiMessage(let message): return message
        case .badResponse: return "Unexpected API response"
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct UIKitTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = .preferredFont(forTextStyle: .body)
        tv.delegate = context.coordinator
        tv.autocorrectionType = .yes
        tv.autocapitalizationType = .sentences
        tv.backgroundColor = .clear
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        tv.text = text
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UIKitTextView
        init(_ parent: UIKitTextView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

#Preview {
    ContentView()
}
