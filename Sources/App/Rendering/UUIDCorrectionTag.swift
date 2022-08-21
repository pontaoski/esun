import Leaf

struct UUIDCorrection: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(1)
        guard let str = ctx.parameters[0].string else {
            throw "first parameter of UUIDCorrection is not a string"
        }
        return .string(str.lowercased().replacingOccurrences(of: "-", with: ""))
    }
}
