import Fluent

struct CreateLotto: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("lottos")
            .id()
            .field("winner_id", .uuid, .references("customers", .id))
            .field("creator_id", .uuid, .required, .references("customers", .id))
            .field("ticket_price", .int, .required)
            .field("max_tickets_per_customer", .int, .required)
            .field("house_cut", .float, .required)
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("slug", .string, .required)
            .create()

        try await database.schema("lotto_tickets")
            .id()
            .field("lotto_id", .uuid, .required, .references("lottos", .id))
            .field("buyer_id", .uuid, .required, .references("customers", .id))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("lottos").delete()
        try await database.schema("lotto_tickets").delete()
    }
}
