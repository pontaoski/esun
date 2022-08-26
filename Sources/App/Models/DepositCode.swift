import Fluent
import Vapor

final class DepositCode: Model {
    static let schema = "deposit_codes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "code")
    var code: String

    @Field(key: "iron_amount")
    var ironAmount: Int

    @Field(key: "diamond_amount")
    var diamondAmount: Int

    @Parent(key: "created_by")
    var createdBy: Customer

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "used_at", on: .delete)
    var usedAt: Date?

    init() {
    }

    init(code: String, iron: Int, diamonds: Int, creator: Customer) {
        self.code = code
        self.ironAmount = iron
        self.diamondAmount = diamonds
        self.$createdBy.id = creator.id!
        self.$createdBy.value = creator
    }
}
