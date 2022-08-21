import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("customers")
            .id()
            .field("iron_balance", .int, .required)
            .field("diamond_balance", .int, .required)
            .create()

        try await database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("created", .bool, .required)
            .field("customer_id", .uuid, .references("customers", .id))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
        try await database.schema("customers").delete()
    }
}
