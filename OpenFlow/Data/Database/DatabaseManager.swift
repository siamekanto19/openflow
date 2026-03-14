import Foundation
import GRDB

/// Manages SQLite database lifecycle and migrations
final class DatabaseManager {
    let dbQueue: DatabaseQueue

    init() throws {
        // ~/Library/Application Support/OpenFlow/openflow.sqlite
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDirectory = appSupport.appendingPathComponent("OpenFlow", isDirectory: true)
        try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)

        let dbPath = dbDirectory.appendingPathComponent("openflow.sqlite").path
        AppLogger.database.info("Database path: \(dbPath)")

        dbQueue = try DatabaseQueue(path: dbPath)
        try migrate()
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            // Transcripts table
            try db.create(table: "transcriptRecord") { t in
                t.column("id", .text).primaryKey()
                t.column("createdAt", .datetime).notNull()
                t.column("rawText", .text).notNull()
                t.column("processedText", .text).notNull()
                t.column("sourceAppName", .text)
                t.column("durationMs", .integer).notNull()
                t.column("languageCode", .text).notNull().defaults(to: "en")
                t.column("insertionMethod", .text).notNull().defaults(to: "paste")
                t.column("status", .text).notNull().defaults(to: "success")
            }

            // Replacement rules table
            try db.create(table: "replacementRule") { t in
                t.column("id", .text).primaryKey()
                t.column("triggerText", .text).notNull()
                t.column("replacementText", .text).notNull()
                t.column("isEnabled", .boolean).notNull().defaults(to: true)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }

        try migrator.migrate(dbQueue)
        AppLogger.database.info("Database migrations completed")
    }
}
