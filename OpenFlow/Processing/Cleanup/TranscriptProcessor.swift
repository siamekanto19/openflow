import Foundation

/// Protocol for transcript processing
protocol TranscriptProcessor {
    func process(_ text: String, profile: FormattingProfile) -> String
}

/// Implements transcript cleanup pipeline
final class TranscriptProcessorImpl: TranscriptProcessor {
    private let replacementRepository: ReplacementRepository

    init(replacementRepository: ReplacementRepository) {
        self.replacementRepository = replacementRepository
    }

    func process(_ text: String, profile: FormattingProfile) -> String {
        var result = text

        // Step 1: Expand spoken commands (before other processing)
        result = expandSpokenCommands(result)

        // Step 2: Trim whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 3: Collapse repeated spaces
        result = collapseSpaces(result)

        // Step 4: Apply profile-specific formatting
        switch profile {
        case .naturalProse:
            result = applyNaturalProseFormatting(result)
        case .literalDictation:
            result = applyLiteralFormatting(result)
        }

        // Step 5: Apply user-defined replacements
        result = applyUserReplacements(result)

        return result
    }

    // MARK: - Spoken Commands

    private func expandSpokenCommands(_ text: String) -> String {
        var result = text

        // Case-insensitive replacements for spoken commands
        let commands: [(pattern: String, replacement: String)] = [
            ("new line", "\n"),
            ("newline", "\n"),
            ("new paragraph", "\n\n"),
            ("period", "."),
            ("full stop", "."),
            ("comma", ","),
            ("question mark", "?"),
            ("exclamation mark", "!"),
            ("exclamation point", "!"),
            ("colon", ":"),
            ("semicolon", ";"),
            ("open quote", "\""),
            ("close quote", "\""),
            ("open parenthesis", "("),
            ("close parenthesis", ")"),
            ("dash", "—"),
            ("hyphen", "-"),
        ]

        for command in commands {
            result = result.replacingOccurrences(
                of: command.pattern,
                with: command.replacement,
                options: .caseInsensitive
            )
        }

        return result
    }

    // MARK: - Formatting

    private func collapseSpaces(_ text: String) -> String {
        text.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
    }

    private func applyNaturalProseFormatting(_ text: String) -> String {
        var result = text

        // Capitalize first letter
        if let first = result.first {
            result = first.uppercased() + result.dropFirst()
        }

        // Capitalize after sentence-ending punctuation
        result = capitalizeAfterPunctuation(result)

        // Remove spaces before punctuation
        result = result.replacingOccurrences(of: " \\.", with: ".", options: .regularExpression)
        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: " \\?", with: "?", options: .regularExpression)
        result = result.replacingOccurrences(of: " !", with: "!")
        result = result.replacingOccurrences(of: " :", with: ":")
        result = result.replacingOccurrences(of: " ;", with: ";")

        // Ensure space after punctuation (except at end)
        result = result.replacingOccurrences(
            of: "([.!?])([A-Za-z])",
            with: "$1 $2",
            options: .regularExpression
        )

        // Add period at end if missing
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !".!?".contains(trimmed.last!) {
            result = trimmed + "."
        }

        return result
    }

    private func applyLiteralFormatting(_ text: String) -> String {
        // Minimal cleanup — just trim and collapse spaces
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func capitalizeAfterPunctuation(_ text: String) -> String {
        var result = ""
        var capitalizeNext = false

        for char in text {
            if capitalizeNext && char.isLetter {
                result.append(char.uppercased().first!)
                capitalizeNext = false
            } else {
                result.append(char)
                if ".!?".contains(char) {
                    capitalizeNext = true
                } else if char.isLetter {
                    capitalizeNext = false
                }
            }
        }

        return result
    }

    // MARK: - User Replacements

    private func applyUserReplacements(_ text: String) -> String {
        var result = text

        do {
            let rules = try replacementRepository.fetchAllEnabled()
            for rule in rules {
                result = result.replacingOccurrences(
                    of: rule.triggerText,
                    with: rule.replacementText,
                    options: .caseInsensitive
                )
            }
        } catch {
            AppLogger.general.error("Failed to load replacement rules: \(error.localizedDescription)")
        }

        return result
    }
}
