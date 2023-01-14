import Fluent
import Vapor
import JSONValueRX

enum BuyableThing: Codable {
    case lotteryTicket(lottery: UUID, name: String, slug: String)
}

final class AuditLogEntry: Model {
    static let schema = "audit_log_entries"

    enum Kind: String, Codable {
        case moneyTransfer
        case balanceAdjustment
        case createDepositCode
        case createWithdrawalCode
        case useDepositCode
        case useWithdrawalCode
        case boughtSomething
    }
    enum Data: Codable {
        case moneyTransfer(iron: Int, diamonds: Int)
        case balanceAdjustment(iron: Int, diamonds: Int)
        case createDepositCode(code: String, iron: Int, diamonds: Int)
        case createWithdrawalCode(code: String, iron: Int, diamonds: Int)
        case useDepositCode(code: String, iron: Int, diamonds: Int)
        case useWithdrawalCode(code: String, iron: Int, diamonds: Int)
        case boughtSomething(iron: Int, diamonds: Int, what: BuyableThing, from: UUID)
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
            case .createDepositCode:
                guard case .createDepositCode = decoded else {
                    throw Abort(.internalServerError, reason: "inconsistent audit log kind and data")
                }
            case .createWithdrawalCode:
                guard case .createWithdrawalCode = decoded else {
                    throw Abort(.internalServerError, reason: "inconsistent audit log kind and data")
                }
            case .useDepositCode:
                guard case .useDepositCode = decoded else {
                    throw Abort(.internalServerError, reason: "inconsistent audit log kind and data")
                }
            case .useWithdrawalCode:
                guard case .useWithdrawalCode = decoded else {
                    throw Abort(.internalServerError, reason: "inconsistent audit log kind and data")
                }
            case .boughtSomething:
                guard case .boughtSomething = decoded else {
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
    static func logCreateDepositCode(by: Customer, code: String, iron: Int, diamonds: Int, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.kind = .createDepositCode
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.createDepositCode(code: code, iron: iron, diamonds: diamonds)))

        try await entry.save(on: db)

        let involvement2 = AuditLogInvolvement()
        involvement2.$customer.id = by.id!
        involvement2.$entry.id = entry.id!
        involvement2.role = "initiator"

        try await involvement2.save(on: db)
    }

    /// assumes database is in a transaction
    static func logBuyingSomething(by: Customer, what: BuyableThing, iron: Int, diamonds: Int, from seller: UUID, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.kind = .boughtSomething
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.boughtSomething(iron: iron, diamonds: diamonds, what: what, from: seller)))

        try await entry.save(on: db)

        let involvement = AuditLogInvolvement()
        involvement.$customer.id = by.id!
        involvement.$entry.id = entry.id!
        involvement.role = "initiator"

        try await involvement.save(on: db)

        let involvement2 = AuditLogInvolvement()
        involvement2.$customer.id = seller
        involvement2.$entry.id = entry.id!
        involvement2.role = "merchant"

        try await involvement2.save(on: db)
    }

    /// assumes database is in a transaction
    static func logCreateWithdrawalCode(by: Customer, code: String, iron: Int, diamonds: Int, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.kind = .createWithdrawalCode
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.createWithdrawalCode(code: code, iron: iron, diamonds: diamonds)))

        try await entry.save(on: db)

        let involvement2 = AuditLogInvolvement()
        involvement2.$customer.id = by.id!
        involvement2.$entry.id = entry.id!
        involvement2.role = "initiator"

        try await involvement2.save(on: db)
    }


    /// assumes database is in a transaction
    static func logUseWithdrawalCode(by: Customer, code: String, iron: Int, diamonds: Int, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.kind = .useWithdrawalCode
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.useWithdrawalCode(code: code, iron: iron, diamonds: diamonds)))

        try await entry.save(on: db)

        let involvement2 = AuditLogInvolvement()
        involvement2.$customer.id = by.id!
        involvement2.$entry.id = entry.id!
        involvement2.role = "initiator"

        try await involvement2.save(on: db)
    }

    /// assumes database is in a transaction
    static func logUseDepositCode(by: Customer, code: String, iron: Int, diamonds: Int, on db: Database) async throws {
        let entry = AuditLogEntry()
        entry.kind = .useDepositCode
        entry.data = try JSONValue.decode(JSONEncoder().encode(Data.useDepositCode(code: code, iron: iron, diamonds: diamonds)))

        try await entry.save(on: db)

        let involvement2 = AuditLogInvolvement()
        involvement2.$customer.id = by.id!
        involvement2.$entry.id = entry.id!
        involvement2.role = "initiator"

        try await involvement2.save(on: db)
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
