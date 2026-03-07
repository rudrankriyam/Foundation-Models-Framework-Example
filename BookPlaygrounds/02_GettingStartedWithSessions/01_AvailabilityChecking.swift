import FoundationModels
import Playgrounds

#Playground {
    // Check Foundation Models availability
    let availability = SystemLanguageModel.default.availability
    print("Availability: \(availability)")

    switch availability {
    case .available:
        print("Foundation Models is available!")
    case .unavailable(let reason):
        print("Foundation Models unavailable: \(reason)")
    }
}
