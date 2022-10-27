import Fluent
import Vapor

enum AuthError: Error {
    case notVerifiedInServer
    case badUUID
}

let usernameUUIDCache = UsernameUUIDCache()

actor UsernameUUIDCache {
    private var usernamesToUUID = [String: UUID]()
    private var uuidsToUsername = [UUID: String]()

    private var activeUsernameTasks = [String: Task<UUID, Error>]()
    private var activeUUIDTasks = [UUID: Task<String, Error>]()

    private var app: Application
    private var client: Client

    init() {
        app = Application()
        client = app.client
    }
    deinit {
        app.shutdown()
    }

    func uuid(for username: String) async throws -> UUID {
        if let uuid = usernamesToUUID[username] {
            return uuid
        }
        if let existingTask = activeUsernameTasks[username] {
            return try await existingTask.value
        }

        let task = Task<UUID, Error> {
            struct Body: Content {
                let name: String
                let id: String
            }

            defer {
                activeUsernameTasks[username] = nil
            }

            let resp = try await client.get("https://api.mojang.com/users/profiles/minecraft/\(username)")
            let body = try resp.content.decode(Body.self)
            let badID = body.id
            let chunkOne = String(badID.prefix(8))
            let chunkTwo = String(badID.dropFirst(8).prefix(4))
            let chunkThree = String(badID.dropFirst(12).prefix(4))
            let chunkFour = String(badID.dropFirst(16).prefix(4))
            let chunkFive = String(badID.suffix(12))
            let cleaned: String = [chunkOne, chunkTwo, chunkThree, chunkFour, chunkFive].joined(separator: "-")

            guard let uuid = UUID(uuidString: cleaned) else {
                throw AuthError.badUUID
            }

            self.usernamesToUUID[username] = uuid
            self.uuidsToUsername[uuid] = username

            return uuid
        }

        activeUsernameTasks[username] = task
        return try await task.value
    }
    func username(for uuid: UUID) async throws -> String {
        if let username = uuidsToUsername[uuid] {
            return username
        }
        if let existingTask = activeUUIDTasks[uuid] {
            return try await existingTask.value
        }

        let task = Task<String, Error> {
            struct Body: Content {
                let name: String
                let id: String
            }

            defer {
                activeUUIDTasks[uuid] = nil
            }

            let cleaned = uuid.uuidString.lowercased().replacingOccurrences(of: "-", with: "")
            let resp = try await client.get("https://sessionserver.mojang.com/session/minecraft/profile/\(cleaned)")
            let body = try resp.content.decode(Body.self)

            self.usernamesToUUID[body.name] = uuid
            self.uuidsToUsername[uuid] = body.name

            return body.name
        }

        activeUUIDTasks[uuid] = task
        return try await task.value
    }
}

class AuthController: RouteCollection {
    private func _authURL() -> String {
        let oauth = Config.instance.oauth
        var builder = URLComponents(string: "https://discord.com/oauth2/authorize")!
        builder.queryItems = [
            URLQueryItem(name: "client_id", value: oauth.clientID),
            URLQueryItem(name: "redirect_uri", value: oauth.redirectURL),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "identify guilds.members.read"),
            URLQueryItem(name: "prompt", value: "none"),
        ]
        return builder.url!.absoluteString
    }
    lazy var authURL: String = _authURL()

    func boot(routes: RoutesBuilder) throws {
        routes.group("auth") { builder in
            builder.get("callback", use: callback)
            builder.get("login", use: goToDiscord)
        }
    }
    func goToDiscord(req: Request) async throws -> Response {
        return req.redirect(to: authURL)
    }
    private func getToken(_ req: Request, for code: String) async throws -> String {
        let oauth = Config.instance.oauth
        struct TokenData: Content {
            let client_id: String
            let client_secret: String
            let grant_type: String = "authorization_code"
            let code: String
            let redirect_uri: String
        }
        struct AccessToken: Content {
            let access_token: String
        }

        let data = TokenData(
            client_id: oauth.clientID,
            client_secret: oauth.clientSecret,
            code: code,
            redirect_uri: Config.instance.oauth.redirectURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        )

        let resp = try await req.client.post("https://discord.com/api/v10/oauth2/token") { rq in
            try rq.content.encode(data, as: .urlEncodedForm)
            rq.headers.contentType = .urlEncodedForm
        }
        let token = try resp.content.decode(AccessToken.self)

        return token.access_token
    }
    private func getDiscordNick(_ req: Request, token: String) async throws -> String {
        struct DiscordUser: Content {
            let username: String
        }
        struct GuildMember: Content {
            let user: DiscordUser
            let nick: String?
            let roles: [String]
        }
        let discord = Config.instance.discord

        let resp = try await req.client.get("https://discord.com/api/v10/users/@me/guilds/\(discord.serverID)/member") { rq in
            rq.headers.add(name: .authorization, value: "Bearer \(token)")
        }
        let member = try resp.content.decode(GuildMember.self)

        guard member.roles.contains(discord.roleID) else {
            throw AuthError.notVerifiedInServer
        }

        return member.nick ?? member.user.username
    }
    func callback(req: Request) async throws -> Response {
        let token = try await getToken(req, for: req.query.get(String.self, at: "code"))
        let nick = try await getDiscordNick(req, token: token)
        guard let user = try await User.get(for: nick, on: req) else {
            throw Abort(.notFound)
        }
        if !user.created {
            user.created = true
            try await user.save(on: req.db)
        }

        let userToken = UUID.generateRandom()
        req.auth.login(user)
        try await req.redis.setex("users/\(userToken)", toJSON: userToken, expirationInSeconds: 3 * 60 * 60 * 24)
        let resp = req.redirect(to: Config.instance.postLoginRedirectURL + "/\(userToken)")
        resp.cookies["AuthToken"] = HTTPCookies.Value(string: userToken.uuidString, isSecure: true)
        return resp
    }
}
