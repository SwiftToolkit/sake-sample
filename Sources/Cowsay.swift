import ArgumentParser
import Foundation

@main
struct SwiftCowsay: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "SwiftCowsay — a talking cow written in Swift 🐄",
        version: cowsayCLIVersion
    )

    @Argument(help: "The message to display in the speech bubble")
    var message: [String]

    @Option(name: .shortAndLong, help: "Maximum line length in the speech bubble")
    var wrap: Int = 40

    func run() throws {
        let cow = Cow()
        let message = message.joined(separator: " ")
        print(cow.say(message, maxLineLength: wrap))
    }
}
