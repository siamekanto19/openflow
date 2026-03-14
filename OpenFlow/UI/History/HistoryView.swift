import SwiftUI

struct HistoryView: View {
    @Environment(RecordingStateStore.self) private var stateStore
    @State private var transcripts: [TranscriptRecord] = []
    @State private var selectedTranscript: TranscriptRecord?
    @State private var searchText = ""
    @State private var isLoading = true

    private var repository: TranscriptRepository? {
        try? TranscriptRepository(database: DatabaseManager())
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar: transcript list
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search transcripts…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                // Transcript list
                if transcripts.isEmpty && !isLoading {
                    ContentUnavailableView {
                        Label("No Transcripts", systemImage: "text.bubble")
                    } description: {
                        Text("Your dictation history will appear here.")
                    }
                } else {
                    List(filteredTranscripts, selection: $selectedTranscript) { transcript in
                        TranscriptRowView(transcript: transcript)
                            .tag(transcript)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive) {
                            clearAllHistory()
                        } label: {
                            Label("Clear All History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        } detail: {
            // Detail: selected transcript
            if let transcript = selectedTranscript {
                TranscriptDetailView(
                    transcript: transcript,
                    onDelete: {
                        deleteTranscript(transcript)
                    }
                )
            } else {
                ContentUnavailableView {
                    Label("Select a Transcript", systemImage: "text.cursor")
                } description: {
                    Text("Choose a transcript from the list to view details.")
                }
            }
        }
        .task {
            await loadTranscripts()
        }
        .onChange(of: searchText) {
            Task { await loadTranscripts() }
        }
    }

    private var filteredTranscripts: [TranscriptRecord] {
        if searchText.isEmpty { return transcripts }
        return transcripts.filter {
            $0.rawText.localizedCaseInsensitiveContains(searchText) ||
            $0.processedText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadTranscripts() async {
        isLoading = true
        do {
            if searchText.isEmpty {
                transcripts = try await repository?.fetchAll() ?? []
            } else {
                transcripts = try await repository?.search(query: searchText) ?? []
            }
        } catch {
            AppLogger.database.error("Failed to load transcripts: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func deleteTranscript(_ transcript: TranscriptRecord) {
        Task {
            try? await repository?.delete(id: transcript.id)
            if selectedTranscript == transcript {
                selectedTranscript = nil
            }
            await loadTranscripts()
        }
    }

    private func clearAllHistory() {
        Task {
            try? await repository?.deleteAll()
            selectedTranscript = nil
            await loadTranscripts()
        }
    }
}

// MARK: - Transcript Row

struct TranscriptRowView: View {
    let transcript: TranscriptRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transcript.processedText)
                .font(.body)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(transcript.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let app = transcript.sourceAppName {
                    Text("• \(app)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text("• \(transcript.formattedDuration)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Transcript Detail

struct TranscriptDetailView: View {
    let transcript: TranscriptRecord
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transcript.formattedDate)
                            .font(.title3.bold())
                        HStack(spacing: 12) {
                            Label(transcript.formattedDuration, systemImage: "clock")
                            if let app = transcript.sourceAppName {
                                Label(app, systemImage: "app")
                            }
                            Label(transcript.insertionMethod, systemImage: "text.cursor")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                // Processed text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Processed Text")
                        .font(.headline)
                    Text(transcript.processedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                // Raw text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Raw Transcript")
                        .font(.headline)
                    Text(transcript.rawText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                Divider()

                // Actions
                HStack(spacing: 12) {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcript.processedText, forType: .string)
                    } label: {
                        Label("Copy Processed", systemImage: "doc.on.doc")
                    }

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcript.rawText, forType: .string)
                    } label: {
                        Label("Copy Raw", systemImage: "doc.on.doc")
                    }

                    Spacer()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .padding(24)
        }
    }
}
