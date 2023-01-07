import Fluent
import Vapor

enum LottoError: Error {
    case notEnoughMoney
    case closedLottery
}

extension Lotto {
    // TODO: guard against buying too many tickets
    func sellTicket(
        to customer: Customer,
        on req: Request
    ) async throws {
        guard self.$winner.id == nil else {
            throw LottoError.closedLottery
        }

        guard customer.diamondBalance >= self.ticketPrice else {
            throw LottoError.notEnoughMoney
        }

        try await req.db.transaction { db in
            customer.diamondBalance -= self.ticketPrice
            try await AuditLogEntry.logBuyingSomething(
                by: customer,
                what: .lotteryTicket(lottery: self.id!, name: self.title, slug: self.slug),
                iron: 0,
                diamonds: self.ticketPrice,
                from: self.$creator.id,
                on: db
            )

            let ticket = LottoTicket()
            ticket.$buyer.id = customer.id!
            ticket.$lotto.id = self.id!

            try await ticket.save(on: db)
        }
    }
}