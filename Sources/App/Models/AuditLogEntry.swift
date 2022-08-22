import Fluent
import Vapor
import JSONValueRX

final class AuditLogEntry: Model {
    static let schema = "audit_log_entries"

    enum Kind: String, Codable {
        case moneyTransfer
    }
    enum Data: Codable {
        case moneyTransfer(iron: Int, diamonds: Int)
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
            }
        }
    }

    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Parent(key: "initiated_by")
    var initiatedBy: Customer

    @Enum(key: "kind")
    var kind: Kind

    @Field(key: "data")
    var data: JSONValue

    @Children(for: \.$entry)
    var involved: [AuditLogInvolvement]

    var recipient: Customer? { involved.get(role: "recipient") }

    /// assumes database is in a transaction
    static func logTransfer(from: Customer, to: Customer, iron: Int, diamonds: Int, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.$initiatedBy.id = from.id!
        entry.kind = .moneyTransfer
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.moneyTransfer(iron: iron, diamonds: diamonds)))

        try await entry.save(on: db)

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
