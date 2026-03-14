import Foundation

/// Formatting profiles for transcript cleanup
enum FormattingProfile: String, Codable, CaseIterable, Identifiable {
    case naturalProse
    case literalDictation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .naturalProse: return "Natural Prose"
        case .literalDictation: return "Literal Dictation"
        }
    }

    var description: String {
        switch self {
        case .naturalProse: return "Better capitalization, punctuation cleanup, and formatting"
        case .literalDictation: return "Minimal interference, more faithful to spoken words"
        }
    }
}
