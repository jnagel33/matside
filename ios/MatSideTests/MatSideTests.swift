import Foundation
import Testing
@testable import MatSide

struct FeedScriptTests {
    @Test func bundledScriptDecodes() {
        let script = FeedScript.bundled()

        #expect(script.bouts.count == 4)
        #expect(!script.frames.isEmpty)
    }
}
