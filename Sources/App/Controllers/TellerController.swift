import Fluent
import Vapor

struct AdjustBalancePage: FormPage {
    static let page = "accounts/teller/adjust-balance/"
    static let route = PathComponent("adjust-balance")

    struct Form: FormData {
        var to: String = ""
        var ironAmount: Int = 0
        var diamondAmount: Int = 0
        var errors: [String] = []
    }
    typealias Success = Self

    let user: User
    let form: Form

    static func submit(form data: Form, on request: Request) async throws -> FormPageResponse<AdjustBalancePage, Success> {
        let user: User = try request.auth.require()
        try await user.$customer.load(on: request.db)
        guard let them: User = try await User.get(for: request.parameters.get("username")!, on: request) else {
            throw Abort(.notFound)
        }
        guard let recipient = try await User.get(for: data.to, on: request) else {
            return .form(AdjustBalancePage(user: them, form: data.with { $0.errors = ["User \(data.to) not found"] }))
        }
        guard them.id == user.id || them.id == recipient.id else {
            return .form(AdjustBalancePage(user: them, form: data.with { $0.errors = ["You seem to be trying to adjust \(them.username)'s balance, but you typed \(recipient.username) instead."]}))
        }

        return try await request.db.transaction { db in
            recipient.customer.ironBalance += data.ironAmount
            recipient.customer.diamondBalance += data.diamondAmount
            try await recipient.customer.save(on: db)
            try await AuditLogEntry.logAdjustment(teller: user.customer, to: recipient.customer, iron: data.ironAmount, diamonds: data.diamondAmount, on: db)

            return .success(AdjustBalancePage(user: them, form: data))
        }
    }

    static func initial(on request: Request) async throws -> AdjustBalancePage {
        let user: User = try request.auth.require()
        try await user.$customer.load(on: request.db)

        return AdjustBalancePage(user: user, form: Form())
    }
}

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

        AdjustBalancePage.register(to: grouped.grouped("accounts", ":username", "teller"))
    }
}
