import Fluent

struct CreateShop: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("shops")
            .id()
            .field("owner", .uuid, .required, .references("customers", .id))
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("slug", .string, .required)
            .create()

        try await database.schema("shop_listings")
            .id()
            .field("shop_id", .uuid, .required, .references("shops", .id))
            .field("created_by", .uuid, .required, .references("customers", .id))
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("stock", .int)
            .field("quantity", .int)
            .field("compacted", .int)
            .create()
    }
    func revert(on database: Database) async throws {
        try await database.schema("shop_listings").delete()
        try await database.schema("shops").delete()
    }
}
