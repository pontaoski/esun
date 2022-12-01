import Fluent
import Vapor

import Foundation

enum SlugConversionError: Error {
    case failedToConvert
}

extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    fileprivate func doConvertSlug() -> String? {
        guard let data = self.data(using: .ascii, allowLossyConversion: true) else {
            return nil
        }
        guard let str = String(data: data, encoding: .ascii) else {
            return nil
        }

        let urlComponents = str.lowercased().components(separatedBy: String.slugSafeCharacters.inverted)
        return urlComponents.filter { $0 != "" }.joined(separator: "-")
    }

    public func convertedToSlug() throws -> String {
        let result: String? = doConvertSlug()

        if let result = result, result.count > 0 {
            return result
        }

        throw SlugConversionError.failedToConvert
    }
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("accounts")
        group.get("me", use: me)
        group.get(":username", use: account)
        group.get(":username", "audit-log", use: auditLog)
        group.get(":username", "shops", use: shops)
        group.post("transfer-money", use: transfer)
        group.post("create-deposit-code", use: createDepositCode)
    }
    struct UserpageData: Content {
        let user: User
    }
    func account(req: Request) async throws -> UserpageData {
        let username = req.parameters.get("username")!
        guard let user = try await User.get(for: username, on: req) else {
            throw Abort(.notFound)
        }
        return UserpageData(user: user)
    }
    func me(req: Request) async throws -> UserpageData {
        let user: User = try req.auth.require()
        return UserpageData(user: user)
    }
    struct AuditLogPageData: Content {
        let pages: Page<AuditLogEntry>
    }
    func auditLog(req: Request) async throws -> AuditLogPageData {
        let username = req.parameters.get("username")!
        guard let user = try await User.get(for: username, on: req) else {
            throw Abort(.notFound)
        }
        let me: User = try req.auth.require()
        guard user.id == me.id else {
            throw Abort(.unauthorized)
        }
        try await me.$customer.load(on: req.db)
        let results = try await AuditLogEntry.query(on: req.db)
            .join(AuditLogInvolvement.self, on: \AuditLogEntry.$id == \AuditLogInvolvement.$entry.$id)
            .filter(AuditLogInvolvement.self, \.$customer.$id == me.customer.id!)
            .with(\.$involved) { $0.with(\.$customer) { $0.with(\.$user) } }
            .sort(\.$createdAt, .descending)
            .paginate(for: req)

        return AuditLogPageData(pages: results)
    }
    struct ShopsPageData: Content {
        let pages: Page<Shop>
    }
    func shops(req: Request) async throws -> ShopsPageData {
        let username = req.parameters.get("username")!
        guard let user = try await User.get(for: username, on: req) else {
            throw Abort(.notFound)
        }

        let results = try await Shop.query(on: req.db)
            .filter(\.$owner.$id == user.customer.id!)
            .paginate(for: req)

        return ShopsPageData(pages: results)
    }

    func transfer(on request: Request) async throws -> Response {
        struct TransferRequest: Content {
            let to: String
            let ironAmount: Int
            let diamondAmount: Int
        }
        enum TransferError: Error {
            case userNotFound(String)
            case negativeMoney
            case notEnoughMoney
        }

        let user: User = try request.auth.require()
        let data = try request.content.decode(TransferRequest.self)
        guard let recipient = try await User.get(for: data.to, on: request) else {
            throw TransferError.userNotFound(data.to)
        }
        guard !(data.ironAmount < 0 || data.diamondAmount < 0) else {
            throw TransferError.negativeMoney
        }

        return try await request.db.transaction { db in
            user.customer.ironBalance -= data.ironAmount
            user.customer.diamondBalance -= data.diamondAmount
            guard user.customer.ironBalance >= 0, user.customer.diamondBalance >= 0 else {
                throw TransferError.notEnoughMoney
            }
            recipient.customer.ironBalance += data.ironAmount
            recipient.customer.diamondBalance += data.diamondAmount
            try await user.customer.save(on: db)
            try await recipient.customer.save(on: db)
            try await AuditLogEntry.logTransfer(from: user.customer, to: recipient.customer, iron: data.ironAmount, diamonds: data.diamondAmount, on: db)

            return Response(status: .ok)
        }
    }
    struct DepositCodeResponse: Content {
        let code: String
    }
    func createDepositCode(on request: Request) async throws -> DepositCodeResponse {
        enum DepositCodeError: Error {
            case notEnoughMoney
            case negativeMoney
            case moneylessDepositCode
        }
        struct DepositCodeRequest: Codable {
            let ironAmount: Int
            let diamondAmount: Int
        }

        let user: User = try request.auth.require()
        let data = try request.content.decode(DepositCodeRequest.self)

        guard data.ironAmount > 0 || data.diamondAmount > 0 else {
            throw DepositCodeError.moneylessDepositCode
        }
        guard !(data.ironAmount < 0 || data.diamondAmount < 0) else {
            throw DepositCodeError.negativeMoney
        }
        guard user.customer.ironBalance >= data.ironAmount && user.customer.diamondBalance >= data.diamondAmount else {
            throw DepositCodeError.notEnoughMoney
        }

        let code = randomString(length: 3) + "-" + randomString(length: 3) + "-" + randomString(length: 4)

        return try await request.db.transaction { db in
            user.customer.ironBalance -= data.ironAmount
            user.customer.diamondBalance -= data.diamondAmount
            try await user.customer.save(on: db)

            let depositCode = DepositCode(code: code.replacingOccurrences(of: "-", with: ""), iron: data.ironAmount, diamonds: data.diamondAmount, creator: user.customer)
            try await depositCode.create(on: db)

            try await AuditLogEntry.logCreateDepositCode(by: user.customer, code: code, iron: data.ironAmount, diamonds: data.diamondAmount, on: db)

            return DepositCodeResponse(code: depositCode.code)
        }
    }
}
