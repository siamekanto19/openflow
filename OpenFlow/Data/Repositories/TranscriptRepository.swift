import Foundation
import GRDB

// MARK: - GRDB Conformance

extension TranscriptRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "transcriptRecord"
}

// MARK: - Repository

final class TranscriptRepository {
    private let database: DatabaseManager

    init(database: DatabaseManager) {
        self.database = database
    }

    func save(_ record: TranscriptRecord) async throws {
        try await database.dbQueue.write { db in
            try record.insert(db)
        }
        AppLogger.database.info("Transcript saved: \(record.id)")
    }

    func fetchRecent(limit: Int = 50) async throws -> [TranscriptRecord] {
        try await database.dbQueue.read { db in
            try TranscriptRecord
                .order(Column("createdAt").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func fetchAll() async throws -> [TranscriptRecord] {
        try await database.dbQueue.read { db in
            try TranscriptRecord
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    func search(query: String) async throws -> [TranscriptRecord] {
        try await database.dbQueue.read { db in
            try TranscriptRecord
                .filter(
                    Column("rawText").like("%\(query)%") ||
                    Column("processedText").like("%\(query)%")
                )
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    func delete(id: UUID) async throws {
        try await database.dbQueue.write { db in
            _ = try TranscriptRecord.deleteOne(db, key: id.uuidString)
        }
        AppLogger.database.info("Transcript deleted: \(id)")
    }

    func deleteAll() async throws {
        try await database.dbQueue.write { db in
            _ = try TranscriptRecord.deleteAll(db)
        }
        AppLogger.database.info("All transcripts deleted")
    }

    func count() async throws -> Int {
        try await database.dbQueue.read { db in
            try TranscriptRecord.fetchCount(db)
        }
    }
}
