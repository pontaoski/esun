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

enum SiteRole: String, Codable {
    case admin
    case teller
    case user

    static func >=(lhs: SiteRole, rhs: SiteRole) -> Bool {
        switch (lhs, rhs) {
        case (.admin, _):
            return true
        case (_, .admin):
            return false
        case (.teller, _):
            return true
        case (_, .teller):
            return false
        default:
            return true
        }
    }
}

final class User: Model, Authenticatable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "created")
    var created: Bool

    @Parent(key: "customer_id")
    var customer: Customer

    @Enum(key: "role")
    var role: SiteRole

    var teller: Bool { role >= .teller }
    var admin: Bool { role >= .admin }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: WriteCodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.username, forKey: .username)
        try container.encode(self.created, forKey: .created)
        if let customer = self.$customer.value {
            try container.encode(customer, forKey: .customer)
        }
        if let role = self.$role.value {
            try container.encode(self.role, forKey: .role)
            try container.encode(self.teller, forKey: .teller)
            try container.encode(self.admin, forKey: .admin)
        } else {
            try container.encode(SiteRole.user, forKey: .role)
            try container.encode(false, forKey: .teller)
            try container.encode(false, forKey: .admin)
        }
    }

    enum WriteCodingKeys: String, CodingKey {
        case id
        case username
        case created
        case customer
        case role
        case teller
        case admin
    }

    init() { }

    init(id: UUID, username: String, customer: Customer) {
        self.id = id
        self.username = username
        self.created = false
        self.$customer.value = customer
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
