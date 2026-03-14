import Foundation
import GRDB

// MARK: - GRDB Conformance

extension ReplacementRule: FetchableRecord, PersistableRecord {
    static let databaseTableName = "replacementRule"
}

// MARK: - Repository

final class ReplacementRepository {
    private let database: DatabaseManager

    init(database: DatabaseManager) {
        self.database = database
    }

    func save(_ rule: ReplacementRule) async throws {
        try await database.dbQueue.write { db in
            try rule.save(db)
        }
        AppLogger.database.info("Replacement rule saved: \(rule.triggerText) → \(rule.replacementText)")
    }

    func fetchAll() async throws -> [ReplacementRule] {
        try await database.dbQueue.read { db in
            try ReplacementRule
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    /// Synchronous version for use in transcript processing
    func fetchAllEnabled() throws -> [ReplacementRule] {
        try database.dbQueue.read { db in
            try ReplacementRule
                .filter(Column("isEnabled") == true)
                .fetchAll(db)
        }
    }

    func update(_ rule: ReplacementRule) async throws {
        var mutable = rule
        mutable.updatedAt = Date()
        let toSave = mutable
        try await database.dbQueue.write { db in
            try toSave.update(db)
        }
    }

    func delete(id: UUID) async throws {
        try await database.dbQueue.write { db in
            _ = try ReplacementRule.deleteOne(db, key: id.uuidString)
        }
        AppLogger.database.info("Replacement rule deleted: \(id)")
    }

    func deleteAll() async throws {
        try await database.dbQueue.write { db in
            _ = try ReplacementRule.deleteAll(db)
        }
    }
}
