import Fluent
import Vapor

final class Customer: Model {
    static let schema = "customers"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "iron_balance")
    var ironBalance: Int

    @Field(key: "diamond_balance")
    var diamondBalance: Int

    @OptionalChild(for: \.$customer)
    var user: User?

    init() {
    }

    init(ironBalance: Int, diamondBalance: Int) {
        self.ironBalance = ironBalance
        self.diamondBalance = diamondBalance
    }
}
