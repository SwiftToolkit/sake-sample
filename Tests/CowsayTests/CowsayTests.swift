@testable import Cowsay
import XCTest

final class CowsayTests: XCTestCase {
    func testCowsayShortMessage() {
        let cow = Cow()
        let message = "Hello, World!"
        let expectedOutput = #"""
         _______________
        < Hello, World! >
         ---------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||
        """#
        let output = cow.say(message, maxLineLength: 40)
        XCTAssertEqual(output, expectedOutput)
    }

    func testCowsayMessageOutOfLimit() {
        let cow = Cow()
        let message = "This is a very long message that exceeds the maximum line length."
        let expectedOutput = #"""
         __________________________________________
        / This is a very long message that exceeds \
        \ the maximum line length.                 /
         ------------------------------------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||
        """#
        let output = cow.say(message, maxLineLength: 40)
        XCTAssertEqual(output, expectedOutput)
    }

    func testCowsayMultipleLinesMessage() {
        let cow = Cow()
        let message = "This is line one.\nThis is line two."
        let expectedOutput = #"""
         _____________________________________
        < This is line one.
        This is line two. >
         -------------------------------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||
        """#
        let output = cow.say(message, maxLineLength: 40)
        XCTAssertEqual(output, expectedOutput)
    }
}
