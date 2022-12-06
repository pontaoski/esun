import Fluent
import Vapor

struct RoleMiddleware: AsyncMiddleware {
    let role: SiteRole

    init(atLeast role: SiteRole) {
        self.role = role
    }
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let user: User = try request.auth.require()
        guard user.role >= role else {
            throw Abort(.forbidden)
        }

        return try await next.respond(to: request)
    }
}

struct TellerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let grouped = routes.grouped(RoleMiddleware(atLeast: .teller))

        grouped.post("accounts", ":username", "teller", "adjust-balance", use: adjustBalance)
        grouped.post("teller", "create-withdrawal-code", use: createWithdrawalCode)
    }
    func adjustBalance(on request: Request) async throws -> Response {
        let user: User = try request.auth.require()
        try await user.$customer.load(on: request.db)
        guard let them: User = try await User.get(for: request.parameters.get("username")!, on: request) else {
            throw Abort(.notFound)
        }
        struct Data: Content {
            let ironAmount: Int
            let diamondAmount: Int
        }
        let data = try request.content.decode(Data.self)

        return try await request.db.transaction { db in
            them.customer.ironBalance += data.ironAmount
            them.customer.diamondBalance += data.diamondAmount
            try await them.customer.save(on: db)
            try await AuditLogEntry.logAdjustment(teller: user.customer, to: them.customer, iron: data.ironAmount, diamonds: data.diamondAmount, on: db)

            return Response(status: .ok)
        }
    }
    struct WithdrawalCodeResponse: Content {
        let code: String
    }
    func createWithdrawalCode(on request: Request) async throws -> WithdrawalCodeResponse {
        enum WithdrawalCodeError: Error {
            case negativeMoney
            case moneylessWithdrawalCode
        }
        struct WithdrawalCodeRequest: Codable {
            let password: String
            let ironAmount: Int
            let diamondAmount: Int
        }

        let user: User = try request.auth.require()
        let data = try request.content.decode(WithdrawalCodeRequest.self)

        guard data.ironAmount > 0 || data.diamondAmount > 0 else {
            throw WithdrawalCodeError.moneylessWithdrawalCode
        }
        guard !(data.ironAmount < 0 || data.diamondAmount < 0) else {
            throw WithdrawalCodeError.negativeMoney
        }

        let code = randomString(length: 3) + "-" + randomString(length: 3) + "-" + randomString(length: 4)

        return try await request.db.transaction { db in
            let withdrawalCode = WithdrawalCode(password: data.password, code: code.replacingOccurrences(of: "-", with: ""), iron: data.ironAmount, diamonds: data.diamondAmount, creator: user.customer)
            try await withdrawalCode.create(on: db)

            try await AuditLogEntry.logCreateWithdrawalCode(by: user.customer, code: code, iron: data.ironAmount, diamonds: data.diamondAmount, on: db)

            return WithdrawalCodeResponse(code: code)
        }
    }
}
