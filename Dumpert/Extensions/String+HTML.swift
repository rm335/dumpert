import Foundation

extension String {
    func strippingHTML() -> String {
        guard !self.isEmpty else { return self }

        // Remove HTML tags
        var result = self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // Decode common HTML entities
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#x27;": "'",
            "&#x2F;": "/",
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Decode numeric HTML entities
        result = result.replacingOccurrences(
            of: "&#(\\d+);",
            with: "",
            options: .regularExpression
        )

        // Trim whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }
}
