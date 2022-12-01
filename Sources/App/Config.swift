import Foundation

struct Config: Codable {
    let oauth: OAuthConfig
    let discord: DiscordConfig
    let postLoginRedirectURL: String
    // let database: DatabaseConfig

    static var instance: Config {
        let conf = try! JSONDecoder().decode(Config.self, from: try! String(contentsOfFile: "config.json").data(using: .utf8)!)
        return conf
    }
}

struct DiscordConfig: Codable {
    let serverID: String
    let roleID: String
}

struct OAuthConfig: Codable {
    let redirectURL: String
    let clientID: String
    let clientSecret: String
}

// struct DatabaseConfig: Codable {
//     let host: String
//     let port: Int
//     let username: String
//     let password: String
//     let database: String
// }
