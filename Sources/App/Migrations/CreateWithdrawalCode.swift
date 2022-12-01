import Fluent

struct CreateWithdrawalCode: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("withdrawal_codes")
            .id()
            .field("code", .string, .required)
            .unique(on: "code", name: "withdrawal_code_unique_code")
            .field("password", .string, .required)
            .field("iron_amount", .int, .required)
            .field("diamond_amount", .int, .required)
            .field("created_by", .uuid, .required, .references("customers", .id))
            .field("created_at", .datetime, .required)
            .field("used_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("withdrawal_codes").delete()
    }
}
