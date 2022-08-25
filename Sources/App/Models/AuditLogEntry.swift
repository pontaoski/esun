import Fluent
import Vapor
import JSONValueRX

final class AuditLogEntry: Model {
    static let schema = "audit_log_entries"

    enum Kind: String, Codable {
        case moneyTransfer
        case balanceAdjustment
    }
    enum Data: Codable {
        case moneyTransfer(iron: Int, diamonds: Int)
        case balanceAdjustment(iron: Int, diamonds: Int)
    }
    struct Validator: AsyncModelMiddleware {
        func create(model: AuditLogEntry, on db: Database, next: AnyAsyncModelResponder) async throws {
            try validate(model)
            return try await next.create(model, on: db)
        }
        func update(model: AuditLogEntry, on db: Database, next: AnyAsyncModelResponder) async throws {
            try validate(model)
            return try await next.update(model, on: db)
        }

        func validate(_ model: AuditLogEntry) throws {
            let decoded: Data = try model.data.decode()
            switch model.kind {
            case .moneyTransfer:
                guard case .moneyTransfer = decoded else {
                    throw Abort(.internalServerError, reason: "inconsistent audit log kind and data")
                }
            case .balanceAdjustment:
                guard case .balanceAdjustment = decoded else {
                    throw Abort(.internalServerError, reason: "inconsistent audit log kind and data")
                }
            }
        }
    }

    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Enum(key: "kind")
    var kind: Kind

    @Field(key: "data")
    var data: JSONValue

    @Children(for: \.$entry)
    var involved: [AuditLogInvolvement]

    var recipient: Customer? { involved.get(role: "recipient") }
    var initiator: Customer? { involved.get(role: "initiator") }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: WriteCodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.createdAt, forKey: .createdAt)
        try container.encode(self.kind, forKey: .kind)
        try container.encode(self.data, forKey: .data)
        try container.encode(self.involved, forKey: .involved)
        try container.encode(self.recipient, forKey: .recipient)
        try container.encode(self.initiator, forKey: .initiator)
    }

    enum WriteCodingKeys: String, CodingKey {
        case id
        case createdAt
        case kind
        case data
        case involved
        case recipient
        case initiator
    }

    /// assumes database is in a transaction
    static func logTransfer(from: Customer, to: Customer, iron: Int, diamonds: Int, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.kind = .moneyTransfer
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.moneyTransfer(iron: iron, diamonds: diamonds)))

        try await entry.save(on: db)

        let involvement2 = AuditLogInvolvement()
        involvement2.$customer.id = from.id!
        involvement2.$entry.id = entry.id!
        involvement2.role = "initiator"

        try await involvement2.save(on: db)

        let involvement = AuditLogInvolvement()
        involvement.$customer.id = to.id!
        involvement.$entry.id = entry.id!
        involvement.role = "recipient"

        try await involvement.save(on: db)
    }

    /// assumes database is in a transaction
    static func logAdjustment(teller: Customer, to: Customer, iron: Int, diamonds: Int, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.kind = .balanceAdjustment
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.balanceAdjustment(iron: iron, diamonds: diamonds)))

        try await entry.save(on: db)

        let involvement2 = AuditLogInvolvement()
        involvement2.$customer.id = teller.id!
        involvement2.$entry.id = entry.id!
        involvement2.role = "initiator"

        try await involvement2.save(on: db)

        let involvement = AuditLogInvolvement()
        involvement.$customer.id = to.id!
        involvement.$entry.id = entry.id!
        involvement.role = "recipient"

        try await involvement.save(on: db)
    }
}

extension Collection where Element == AuditLogInvolvement {
    func get(role: String) -> Customer? {
        self.filter { $0.role == role }.first?.customer
    }
}

final class AuditLogInvolvement: Model {
    static let schema = "audit_log_involvements"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "entry_id")
    var entry: AuditLogEntry

    @Parent(key: "customer_id")
    var customer: Customer

    @Field(key: "role")
    var role: String
}
