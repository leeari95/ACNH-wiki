import Foundation

struct VariantID: Hashable, Codable {
    let value: String
    
    init(filename: String) {
        self.value = filename
    }
    
    init(_ value: String) {
        self.value = value
    }
}

extension VariantID: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.value = value
    }
}

extension VariantID: CustomStringConvertible {
    var description: String {
        return value
    }
}
