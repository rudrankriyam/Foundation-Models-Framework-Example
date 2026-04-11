import Testing
@testable import AFMCLI

@Test("The startup banner matches the public command name")
func startupBannerMatchesCommandName() {
    #expect(AFMCLI.startupBanner() == "afm")
}
