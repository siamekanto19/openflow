import SwiftUI

struct ReplacementsSettingsView: View {
    @State private var rules: [ReplacementRule] = []
    @State private var newTrigger = ""
    @State private var newReplacement = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var repository: ReplacementRepository? {
        try? ReplacementRepository(database: DatabaseManager())
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    TextField("Trigger text", text: $newTrigger)
                        .textFieldStyle(.roundedBorder)

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    TextField("Replacement text", text: $newReplacement)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        addRule()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                    .disabled(newTrigger.isEmpty || newReplacement.isEmpty)
                }
            } header: {
                Text("Add Rule")
            } footer: {
                Text("Text substitutions are applied automatically after transcription.")
            }

            Section {
                if rules.isEmpty && !isLoading {
                    Text("No replacement rules defined.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rules) { rule in
                        HStack(spacing: 10) {
                            Toggle("", isOn: Binding(
                                get: { rule.isEnabled },
                                set: { enabled in toggleRule(rule, enabled: enabled) }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .controlSize(.small)

                            Label {
                                HStack(spacing: 6) {
                                    Text(rule.triggerText)
                                        .fontWeight(.medium)
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text(rule.replacementText)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "text.badge.star")
                                    .foregroundStyle(.purple)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                deleteRule(rule)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                if let error = errorMessage {
                    Label(error, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            } header: {
                Text("Active Rules")
            }
        }
        .formStyle(.grouped)
        .task {
            await loadRules()
        }
    }

    private func loadRules() async {
        isLoading = true
        do {
            rules = try await repository?.fetchAll() ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func addRule() {
        let rule = ReplacementRule(triggerText: newTrigger, replacementText: newReplacement)
        Task {
            do {
                try await repository?.save(rule)
                newTrigger = ""
                newReplacement = ""
                await loadRules()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func toggleRule(_ rule: ReplacementRule, enabled: Bool) {
        var updated = rule
        updated.isEnabled = enabled
        Task {
            try? await repository?.update(updated)
            await loadRules()
        }
    }

    private func deleteRule(_ rule: ReplacementRule) {
        Task {
            try? await repository?.delete(id: rule.id)
            await loadRules()
        }
    }
}
