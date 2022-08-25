import Fluent

struct CreateAuditLog: AsyncMigration {
    func prepare(on database: Database) async throws {
        let kindEnum = try await database.enum("audit_log_entry_kind")
            .case("moneyTransfer")
            .create()

        try await database.schema("audit_log_entries")
            .id()
            .field("created_at", .datetime, .required)
            .field("kind", kindEnum, .required)
            .field("data", .json, .required)
            .create()

        try await database.schema("audit_log_involvements")
            .id()
            .field("entry_id", .uuid, .required, .references("audit_log_entries", .id))
            .field("customer_id", .uuid, .required, .references("customers", .id))
            .field("role", .string, .required)
            .create()
    }
    func revert(on database: Database) async throws {
        try await database.schema("audit_log_involvements").delete()
        try await database.schema("audit_log_entries").delete()
        try await database.enum("audit_log_entry_kind").delete()
    }
}