final class Cow {
    func say(_ message: String, maxLineLength: Int) -> String {
        var buffer = ""
        let lines = splitMessage(message, maxLineLength: maxLineLength)
        printSpeechBubble(lines, to: &buffer)
        printCow(to: &buffer)
        return buffer
    }

    private func splitMessage(_ message: String, maxLineLength: Int) -> [String] {
        var result: [String] = []
        var currentLine = ""

        for word in message.split(separator: " ") {
            if currentLine.count + word.count + 1 > maxLineLength {
                result.append(currentLine)
                currentLine = String(word)
            } else {
                currentLine += (currentLine.isEmpty ? "" : " ") + word
            }
        }
        if !currentLine.isEmpty {
            result.append(currentLine)
        }
        return result
    }

    private func printSpeechBubble(_ lines: [String], to buffer: inout String) {
        let maxLength = lines.map(\.count).max() ?? 0
        let top = " " + String(repeating: "_", count: maxLength + 2)
        let bottom = " " + String(repeating: "-", count: maxLength + 2)

        buffer += top + "\n"
        for (index, line) in lines.enumerated() {
            let padding = String(repeating: " ", count: maxLength - line.count)
            let (left, right) = switch (index, lines.count) {
            case (0, 1): ("<", ">")
            case (0, _): ("/", "\\")
            case let (_, count) where index == count - 1: ("\\", "/")
            default: ("|", "|")
            }
            buffer += "\(left) \(line)\(padding) \(right)\n"
        }
        buffer += bottom + "\n"
    }

    private func printCow(to buffer: inout String) {
        buffer += #"""
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||
        """#
    }
}
