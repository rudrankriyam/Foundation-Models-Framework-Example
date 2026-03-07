import FoundationModels
import Playgrounds
import Foundation

#Playground {
    let model = SystemLanguageModel.default
    let supportedLanguages = model.supportedLanguages

    for language in supportedLanguages {
        let code = language.languageCode?.identifier ?? ""
        let region = language.region?.identifier ?? ""

        let name = Locale.current.localizedString(forLanguageCode: code) ?? code
        let regionName = region.isEmpty ? nil : (Locale.current.localizedString(forRegionCode: region) ?? region)

        if let regionName = regionName {
            debugPrint("- \(name) (\(regionName))")
        } else {
            debugPrint("- \(name)")
        }
    }
}
