import FoundationModels
import Playgrounds
import Foundation

#Playground {
    let model = SystemLanguageModel.default
    let supportedLanguages = model.supportedLanguages

    for language in supportedLanguages {
        let lang = language.languageCode?.identifier ?? "unknown"
        let region = language.region?.identifier ?? "—"
        debugPrint("- \(lang) (\(region))")
    }
}