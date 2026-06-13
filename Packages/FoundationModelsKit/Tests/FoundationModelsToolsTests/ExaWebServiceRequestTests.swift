import Testing
@testable import FoundationModelsTools

@Suite("ExaWebService Request Tests")
struct ExaWebServiceRequestTests {
  @Test("Search request carries every tool option")
  func searchRequestCarriesEveryToolOption() {
    let request = ExaWebService().makeSearchRequest(
      query: "foundation models",
      numResults: 7,
      type: "deep",
      includeContents: true,
      category: "research paper"
    )

    #expect(request.query == "foundation models")
    #expect(request.numResults == 7)
    #expect(request.type == "deep")
    #expect(request.contents?.text == true)
    #expect(request.category == "research paper")
  }

  @Test("Search request normalizes defaults and bounds")
  func searchRequestNormalizesDefaultsAndBounds() {
    let request = ExaWebService().makeSearchRequest(
      query: "swift",
      numResults: 99,
      type: " ",
      includeContents: false,
      category: " "
    )

    #expect(request.numResults == 10)
    #expect(request.type == "auto")
    #expect(request.contents == nil)
    #expect(request.category == nil)
  }
}
