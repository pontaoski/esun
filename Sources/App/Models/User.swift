import Fluent
import Vapor

extension UUID {
    init?(fromMCUUID it: String) {
        let frag1 = it.dropFirst(0).prefix(8)
        let frag2 = it.dropFirst(8).prefix(4)
        let frag3 = it.dropFirst(8 + 4).prefix(4)
        let frag4 = it.dropFirst(8 + 4 + 4).prefix(4)
        let frag5 = it.dropFirst(8 + 4 + 4 + 4).prefix(12)

        let cleaned = "\(frag1)-\(frag2)-\(frag3)-\(frag4)-\(frag5)"

        self.init(cleaned)
    }
}

final class User: Model, ModelSessionAuthenticatable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "created")
    var created: Bool

    @Parent(key: "customer_id")
    var customer: Customer

    init() { }

    init(id: UUID, username: String, customer: Customer) {
        self.id = id
        self.username = username
        self.created = false
        self.$customer.id = customer.id!
    }

    static func get(for username: String, on req: Request) async throws -> User? {
        let resp = try await req.client.get("https://api.mojang.com/users/profiles/minecraft/\(username)")
        struct Resp: Codable {
            let id: String
        }
        guard let it: Resp = try? resp.content.decode(Resp.self) else {
            return nil
        }
        guard let id = UUID(fromMCUUID: it.id) else {
            return nil
        }
        let user: User
        if let found = try await User.query(on: req.db).with(\.$customer).filter(\.$id == id).first() {
            user = found
            if user.username != username {
                user.username = username
                try await user.save(on: req.db)
            }
        } else {
            let customer = Customer(ironBalance: 0, diamondBalance: 0)
            user = try await req.db.transaction { db in
                try await customer.save(on: db)
                let user = User(id: id, username: username, customer: customer)
                try await user.save(on: db)
                return user
            }
        }
        return user
    }
}
