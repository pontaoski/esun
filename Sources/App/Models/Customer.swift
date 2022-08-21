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

    init() {
    }

    init(ironBalance: Int, diamondBalance: Int) {
        self.ironBalance = ironBalance
        self.diamondBalance = diamondBalance
    }
}
