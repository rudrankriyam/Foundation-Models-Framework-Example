import Foundation

@main
struct AFMCLI {
    static let commandName = "afm"

    static func startupBanner() -> String {
        commandName
    }

    static func main() {
        print(startupBanner())
    }
}
