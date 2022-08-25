import Fluent
import Vapor

struct TransferPage: FormPage {
    static let page = "accounts/transfer-funds/"
    static let route = PathComponent("transfer-funds")

    struct Form: FormData {
        var to: String = ""
        var ironAmount: Int = 0
        var diamondAmount: Int = 0
        var errors: [String] = []
    }
    typealias Success = Self

    let user: User
    let form: Form

    static func submit(form data: Form, on request: Request) async throws -> FormPageResponse<TransferPage, Success> {
        let user: User = try request.auth.require()
        try await user.$customer.load(on: request.db)
        guard let them: User = try await User.get(for: request.parameters.get("username")!, on: request) else {
            throw Abort(.notFound)
        }
        guard let recipient = try await User.get(for: data.to, on: request) else {
            return .form(TransferPage(user: them, form: Form(errors: ["User \(data.to) not found"])))
        }
        guard them.id == user.id || them.id == recipient.id else {
            return .form(TransferPage(user: them, form: Form(errors: ["You seem to be trying to transfer money to \(them.username), but you typed \(recipient.username) instead."])))
        }

        return try await request.db.transaction { db in
            user.customer.ironBalance -= data.ironAmount
            user.customer.diamondBalance -= data.diamondAmount
            recipient.customer.ironBalance += data.ironAmount
            recipient.customer.diamondBalance += data.diamondAmount
            try await user.customer.save(on: db)
            try await recipient.customer.save(on: db)
            try await AuditLogEntry.logTransfer(from: user.customer, to: recipient.customer, iron: data.ironAmount, diamonds: data.diamondAmount, on: db)

            return .success(TransferPage(user: them, form: data))
        }
    }
    static func initial(on request: Request) async throws -> TransferPage {
        let me: User = try request.auth.require()
        guard let them: User = try await User.get(for: request.parameters.get("username")!, on: request) else {
            throw Abort(.notFound)
        }
        if them.id != me.id {
            return TransferPage(user: them, form: Form(to: them.username))
        } else {
            return TransferPage(user: me, form: Form())
        }
    }
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("accounts")
        group.grouped(AlwaysTrailingSlashMiddleware()).get(":username", use: account)
        group.get(":username", "audit-log", use: auditLog)
        group.get("@me") { req -> Response in
            let who: User = try req.auth.require()
            return req.redirect(to: "/accounts/\(who.username)")
        }
        TransferPage.register(to: group.grouped(":username"))
    }
    struct UserpageData: Codable {
        let user: User?
    }
    func account(req: Request) async throws -> View {
        let username = req.parameters.get("username")!
        let user = try await User.get(for: username, on: req)
        return try await req.view.render("accounts/user", UserpageData(user: user))
    }
    struct AuditLogPageData: Codable {
        let user: User
        let pages: Page<AuditLogEntry>
    }
    func auditLog(req: Request) async throws -> View {
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

        return try await req.view.render("accounts/audit-log/index", AuditLogPageData(user: user, pages: results))
    }
}
