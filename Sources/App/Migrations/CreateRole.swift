import Fluent

struct CreateRole: AsyncMigration {
    func prepare(on database: Database) async throws {
        let roleEnum = try await database.enum("site_role")
            .case("admin")
            .case("teller")
            .case("user")
            .create()

        try await database.schema("users")
            .field("role", roleEnum, .required, .sql(.default("user")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("role")
            .update()

        try await database.enum("site_role")
            .delete()
    }
}