import BackgroundAssets
import CoreGraphics
import Foundation
import Observation
import _Concurrency
import _StringProcessing
import _SwiftConcurrencyShims

/// A type that can be initialized from generated content.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol ConvertibleFromGeneratedContent {

    /// Creates an instance with the content.
    init(_ content: GeneratedContent) throws
}

/// A type that can be converted to generated content.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol ConvertibleToGeneratedContent : InstructionsRepresentable, PromptRepresentable {

    /// An instance that represents the generated content.
    var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ConvertibleToGeneratedContent {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}

/// The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.
///
/// An individual schema may reference other schemas by
/// name, and references are resolved when converting a set of
/// dynamic schemas into a ``GenerationSchema``.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct DynamicGenerationSchema : Sendable {

    /// Creates an object schema.
    ///
    /// - Parameters:
    ///   - name: A name this dynamic schema can be referenced by.
    ///   - description: A natural language description of this schema.
    ///   - properties: The properties to associated with this schema.
    public init(name: String, description: String? = nil, properties: [DynamicGenerationSchema.Property])

    /// Creates an any-of schema.
    ///
    /// - Parameters:
    ///   - name: A name this schema can be referenecd by.
    ///   - description: A natural language description of this ``DynamicGenerationSchema``.
    ///   - choices: An array of schemas this one will be a union of.
    public init(name: String, description: String? = nil, anyOf choices: [DynamicGenerationSchema])

    /// Creates an enum schema.
    ///
    /// - Parameters:
    ///   - name: A name this schema can be referenced by.
    ///   - description: A natural language description of this ``DynamicGenerationSchema``.
    ///   - choices: An array of schemas this one will be a union of.
    public init(name: String, description: String? = nil, anyOf choices: [String])

    /// Creates an array schema.
    ///
    /// - Parameters:
    ///   - arrayOf: A schema to use as the elements of the array.
    public init(arrayOf itemSchema: DynamicGenerationSchema, minimumElements: Int? = nil, maximumElements: Int? = nil)

    /// Creates a dictionary schema.
    ///
    /// - Parameters:
    ///   - dictionaryOf: A schema to use as the values of the dictionary.
    public init(dictionaryOf valueSchema: DynamicGenerationSchema)

    /// Creates a schema from a generable type and guides.
    ///
    /// - Parameters:
    ///   - type: A `Generable` type
    ///   - guides: Generation guides to apply to this `DynamicGenerationSchema`.
    public init<Value>(type: Value.Type, guides: [GenerationGuide<Value>] = []) where Value : Generable

    /// Creates an refrence schema.
    ///
    /// - Parameters:
    ///   - name: The name of the ``DynamicGenerationSchema`` this is a reference to.
    public init(referenceTo name: String)

    /// A property that belongs to a dynamic generation schema.
    ///
    /// Fields are named members of object types. Fields are strongly
    /// typed and have optional descriptions.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Property {

        /// Creates a property referencing a dynamic schema.
        ///
        /// - Parameters:
        ///   - name: A name for this property.
        ///   - description: An optional natural language description of this
        ///     property's contents.
        ///   - schema: A schema representing the type this property contains.
        ///   - isOptional: Determines if this property is required or not.
        public init(name: String, description: String? = nil, schema: DynamicGenerationSchema, isOptional: Bool = false)
    }
}

/// Conforming types represent data types a system language model generates.
///
/// Annotate your model types with the `@Generable` macro to allow the model to respond
/// to prompts by generating an instance of your type. Use the `@Guide` macro to provide
/// natural language descriptions of your properties, and programmatically control
/// the values that the model can generate.
///
/// ```swift
/// @Generable
/// struct SearchSuggestions {
///
///     @Guide(description: "A list of suggested search terms", .count(4))
///     var searchTerms: [SearchTerm]
///
///     @Generable
///     struct SearchTerm {
///         @Guide(description: "A unique id", .pattern(/search-term-\d/))
///         var id: String
///
///         @Guide(description: "A 2 or 3 word search term, like 'Beautiful sunsets'")
///         var searchTerm: String
///     }
/// }
/// ```
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol Generable : ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent {

    /// A representation of partially generated content
    associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self

    /// An instance of the generation schema.
    static var generationSchema: GenerationSchema { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Generable {

    /// The partially generated type of this struct.
    public func asPartiallyGenerated() -> Self.PartiallyGenerated
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Generable {

    /// A representation of partially generated content
    public typealias PartiallyGenerated = Self
}

/// Conforms a type to generable.
///
/// You can apply this macro to structures and enumerations.
///
/// ```swift
/// @Generable
/// struct NovelIdea {
///   @Guide(description: "A short title")
///   let title: String
///
///   @Guide(description: "A short subtitle for the novel")
///   let subtitle: String
///
///   @Guide(description: "The genre of the novel")
///   let genre: Genre
/// }
///
/// @Generable
/// enum Genre {
///   case fiction
///   case nonFiction
/// }
/// ```
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent)) @attached(member, names: arbitrary) public macro Generable(description: String? = nil) = #externalMacro(module: "FoundationModelsMacros", type: "GenerableMacro")

/// A type that represents generated content.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct GeneratedContent : Sendable, Equatable, Generable, CustomDebugStringConvertible, ConvertibleToGeneratedContent {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// A unique id that is stable for duration of a generated response.
    public var id: GenerationID?

    /// Creates an object with the content you specify.
    public init(_ content: GeneratedContent) throws

    /// A representation of this instance.
    public var generatedContent: GeneratedContent { get }

    /// Creates an object with the properties you specify.
    ///
    /// The order of properties is important. For ``Generable`` types, the order
    /// must match the order properties in the types `schema`.
    public init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>)

    /// Creates an object with an array of elements you specify.
    ///
    public init<C>(elements: C) where C : Collection, C.Element == any ConvertibleToGeneratedContent

    /// Creates an object that contains a single value.
    ///
    public init(_ content: some ConvertibleToGeneratedContent)

    /// Reads a top level, concrete partially generable type.
    public func value<Value>(_ type: Value.Type = Value.self) throws -> Value where Value : ConvertibleFromGeneratedContent

    /// Reads a top level array of content.
    public func elements() throws -> [GeneratedContent]

    /// Reads the properties of a top level object
    public func properties() throws -> [String : GeneratedContent]

    /// Reads a concrete generable type from named property.
    public func value<Value>(_ type: Value.Type = Value.self, forProperty property: String) throws -> Value where Value : ConvertibleFromGeneratedContent

    /// Reads an optional, concrete generable type from named property.
    public func value<Value>(_ type: Value?.Type = Value?.self, forProperty property: String) throws -> Value? where Value : ConvertibleFromGeneratedContent

    /// A string representation for the debug description.
    public var debugDescription: String { get }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: GeneratedContent, b: GeneratedContent) -> Bool
}

/// Guides that control how values are generated.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct GenerationGuide<Value> : Sendable {
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GenerationGuide where Value == String {

    /// Enforces that the string be precisely the given value.
    public static func constant(_ value: String) -> GenerationGuide<String>

    /// Enforces that the string be one of the provided values.
    public static func anyOf(_ values: [String]) -> GenerationGuide<String>

    /// Enforces that the string follows the pattern.
    public static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String>
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GenerationGuide where Value == Int {

    /// Enforces a minimum value.
    ///
    /// The bounds are inclusive.
    public static func minimum(_ value: Int) -> GenerationGuide<Int>

    /// Enforces a maximum value.
    ///
    /// The bounds are inclusive.
    public static func maximum(_ value: Int) -> GenerationGuide<Int>

    /// Enforces values fall within a range.
    public static func range(_ range: ClosedRange<Int>) -> GenerationGuide<Int>
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GenerationGuide where Value == Float {

    /// Enforces a minimum value.
    ///
    /// The bounds are inclusive.
    public static func minimum(_ value: Float) -> GenerationGuide<Float>

    /// Enforces a maximum value.
    ///
    /// The bounds are inclusive.
    public static func maximum(_ value: Float) -> GenerationGuide<Float>

    /// Enforces values fall within a range.
    public static func range(_ range: ClosedRange<Float>) -> GenerationGuide<Float>
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GenerationGuide where Value == Decimal {

    /// Enforces a minimum value.
    ///
    /// The bounds are inclusive.
    public static func minimum(_ value: Decimal) -> GenerationGuide<Decimal>

    /// Enforces a maximum value.
    ///
    /// The bounds are inclusive.
    public static func maximum(_ value: Decimal) -> GenerationGuide<Decimal>

    /// Enforces values fall within a range.
    public static func range(_ range: ClosedRange<Decimal>) -> GenerationGuide<Decimal>
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GenerationGuide where Value == Double {

    /// Enforces a minimum value.
    /// The bounds are inclusive.
    public static func minimum(_ value: Double) -> GenerationGuide<Double>

    /// Enforces a maximum value.
    /// The bounds are inclusive.
    public static func maximum(_ value: Double) -> GenerationGuide<Double>

    /// Enforces values fall within a range.
    public static func range(_ range: ClosedRange<Double>) -> GenerationGuide<Double>
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GenerationGuide {

    /// Enforces a minimum number of elements in the array.
    ///
    /// The bounds are inclusive.
    public static func minimumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces a maximum number of elements in the array.
    ///
    /// The bounds are inclusive.
    public static func maximumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces that the number of elements in the array fall within a closed range.
    public static func count<Element>(_ range: ClosedRange<Int>) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces that the array has exactly a certain number elements.
    public static func count<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

    /// Enforces a guide on the elements within the array.
    public static func element<Element>(_ guide: GenerationGuide<Element>) -> GenerationGuide<[Element]> where Value == [Element]
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GenerationGuide where Value == [Never] {

    /// Enforces a minimum number of elements in the array.
    ///
    /// Bounds are inclusive.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.minimumCount(_:)` on your own.
    public static func minimumCount(_ count: Int) -> GenerationGuide<Value>

    /// Enforces a maximum number of elements in the array.
    ///
    /// Bounds are inclusive.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.maximumCount(_:)` on your own.
    public static func maximumCount(_ count: Int) -> GenerationGuide<Value>

    /// Enforces that the number of elements in the array fall within a closed range.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.count(_:)` on your own.
    public static func count(_ range: ClosedRange<Int>) -> GenerationGuide<Value>

    /// Enforces that the array has exactly a certain number elements.
    ///
    /// - Warning: This overload is only used for macro expansion. Don't call `GenerationGuide<[Never]>.count(_:)` on your own.
    public static func count(_ count: Int) -> GenerationGuide<Value>
}

/// A unique identifier that is stable for the duration of a response,
/// but not across responses.
///
///     @Generable struct Person: Equatable {
///         var id: GenerationID
///         var name: String
///     }
///
///     struct PeopleView: View {
///         @State private var session = LanguageModelSession()
///         @State private var people = [Person.PartiallyGenerated]()
///
///         var body: some View {
///             // A person's name changes as the response is generated,
///             // and two people can have the same name, so it is not suitable
///             // for use as an id.
///             //
///             // `GenerationID` receives special treatment and is guaranteed
///             // to be both present and stable.
///             List {
///                 ForEach(people) { person in
///                     Text("Name: \(person.name)")
///                 }
///             }
///             .task {
///                 for try! await people in stream.streamResponse(
///                     to: "Who were the first 3 presidents of the US?",
///                     generating: [Person].self
///                 ) {
///                     withAnimation {
///                         self.people = people
///                     }
///                 }
///             }
///         }
///     }
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct GenerationID : Sendable, Hashable {

    /// Create a new, unique `GenerationID`.
    public init()

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: GenerationID, b: GenerationID) -> Bool

    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// Implement this method to conform to the `Hashable` protocol. The
    /// components used for hashing must be the same as the components compared
    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
    /// with each of these components.
    ///
    /// - Important: In your implementation of `hash(into:)`,
    ///   don't call `finalize()` on the `hasher` instance provided,
    ///   or replace it with a different instance.
    ///   Doing so may become a compile-time error in the future.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
    public func hash(into hasher: inout Hasher)

    /// The hash value.
    ///
    /// Hash values are not guaranteed to be equal across different executions of
    /// your program. Do not save hash values to use during a future execution.
    ///
    /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
    ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
    ///   The compiler provides an implementation for `hashValue` for you.
    public var hashValue: Int { get }
}

/// Options that control how the model generates its response to a prompt.
///
/// Create a ``GenerationOptions`` structure when you want to adjust
/// the way the model generates its response. Use this structure to
/// perform various adjustments on how the model chooses output tokens,
/// to specify the penalties for repeating tokens or generating
/// longer responses.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct GenerationOptions : Sendable, Equatable {

    /// A type that defines how values are sampled from a probability distribution.
    ///
    /// A model builds its response to a prompt in a loop. At each iteration in the
    /// loop the model produces a probability distribution for all the tokens in its
    /// vocabulary. The sampling mode controls how a token is selected from that
    /// distribution.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct SamplingMode : Sendable, Equatable {

        /// A sampling mode that always chooses the most likely token.
        ///
        /// Using this mode will always result in the same output
        /// for a given input. Responses produced with greedy sampling
        /// are statistically likely, but may lack the human-like quality
        /// and variety of other sampling strategies.
        public static var greedy: GenerationOptions.SamplingMode { get }

        /// A sampling mode that considers a fixed number of high-probability tokens.
        ///
        /// Also known as top-k.
        ///
        /// During the token-selection process, the vocabulary is sorted by probability a
        /// token is selected from among the top K candidates. Smaller values of K will
        /// ensure only the most probable tokens are candidates for selection, resulting
        /// in more deterministic and confident answers. Larger values of K will allow less
        /// probably tokens to be selected, raising non-determinism and creativity.
        ///
        /// - Note: Setting a random seed is not guaranteed to result in fully deterministic
        ///   output. It is best effort.
        ///
        /// - Parameters:
        ///   - top: The number of tokens to consider.
        ///   - seed: An optional random seed used to make output more deterministic.
        public static func random(top k: Int, seed: UInt64? = nil) -> GenerationOptions.SamplingMode

        /// A mode that considers a variable number of high-probability tokens
        /// based on the specified threshold.
        ///
        /// Also known as top-p or nucleus sampling.
        ///
        /// With nucleus sampling, tokens are sorted by probability and added to a
        /// pool of candidates until the cumulative probability of the pool exceeds
        /// the specified threshold, and then a token is sampled from the pool.
        ///
        /// Because the number of tokens isn't predetermined, the selection pool size
        /// will be larger when the distribution is flat and smaller when it is spikey.
        /// This variability can lead to a wider variety of options to choose from, and
        /// potentially more creative responses.
        ///
        /// - Note: Setting a random seed is not guaranteed to result in fully deterministic
        ///   output. It is best effort.
        ///
        /// - Parameters:
        ///     - probabilityThreshold: A number between `0.0` and `1.0` that
        ///       increases sampling pool size.
        ///     - seed: An optional random seed used to make output more deterministic.
        public static func random(probabilityThreshold: Double, seed: UInt64? = nil) -> GenerationOptions.SamplingMode

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: GenerationOptions.SamplingMode, b: GenerationOptions.SamplingMode) -> Bool
    }

    /// A sampling strategy for how the model picks tokens when generating a
    /// response.
    ///
    /// When you execute a prompt on a model, the model produces a probability
    /// for every token in its vocabulary. The sampling strategy controls how
    /// the model narrows down the list of tokens to consider during that process.
    /// A strategy that picks the single most likely token yields a predictable
    /// response every time, but other strategies offer results that often
    /// sound more natural to a person.
    ///
    /// - Note: Leaving the `sampling` nil lets the system choose a
    ///   a reasonable default on your behalf.
    public var sampling: GenerationOptions.SamplingMode?

    /// Temperature influences the confidence of the models response.
    ///
    /// The value of this property must be a number between `0` and `2` inclusive.
    ///
    /// Temperature is an adjustment applied  to the probability distribution
    /// prior to sampling. A value of `1` results in no adjustment. Values less
    /// than `1` will make the probability distribution sharper, with already
    /// likely tokens becoming even more likely. Values greather than `1` will
    /// flatten the distribution, making less probable tokens more likely.
    ///
    /// The net effect is that low temperatures manifest as more stable and
    /// predictable responses, while high temperatures give the model more
    /// creative license.
    ///
    /// - Note: Leaving `temperature` nil lets the system choose a reasonable
    ///   default on your behalf.
    public var temperature: Double?

    /// The maximum number of tokens the model is allowed to produce in its response.
    ///
    /// If the model produce `maximumResponseTokens` before it naturally completes its response,
    /// the response will be terminated early. No error will be thrown. This property
    /// can be used to protect against unexpectedly verbose responses and runaway generations.
    ///
    /// If no value is specified, then the model is allowed to produce the longest answer
    /// its context size supports. If the response exceeds that limit without terminating,
    /// an error will be thrown.
    public var maximumResponseTokens: Int?

    /// Creates generation options that control token sampling behavior.
    ///
    /// - Parameters:
    ///   - sampling: A strategy to use for sampling from a distribution.
    ///   - temperature: Increasing temperature makes it possible for the model to produce less likely
    ///     responses. Must be between 0 and 2, inclusive.
    ///   - maximumResponseTokens: The maximum number of tokens the model is allowed
    ///     to produce before being artificially halted. Must be positive.
    public init(sampling: GenerationOptions.SamplingMode? = nil, temperature: Double? = nil, maximumResponseTokens: Int? = nil)

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: GenerationOptions, b: GenerationOptions) -> Bool
}

/// A type that describes the properties of an object and any guides
/// on their values.
///
/// Generation  schemas guide the output of a ``SystemLanguageModel`` to deterministically
/// ensure the output is in the desired format.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct GenerationSchema : Sendable, CustomDebugStringConvertible {

    /// A property that belongs to a generation schema.
    ///
    /// Fields are named members of object types. Fields are strongly
    /// typed and have optional descriptions and guides.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Property : Sendable {

        /// Create a property that contains a generable type.
        ///
        /// - Parameters:
        ///   - name: The property's name.
        ///   - description: A natural language description of what content
        ///     should be generated for this property.
        ///   - type: The type this property represents.
        ///   - guides: A list of guides to apply to this property.
        public init<Value>(name: String, description: String? = nil, type: Value.Type, guides: [GenerationGuide<Value>] = []) where Value : Generable

        /// Create an optional property that contains a generable type.
        ///
        /// - Parameters:
        ///   - name: The property's name.
        ///   - description: A natural language description of what content
        ///     should be generated for this property.
        ///   - type: The type this property represents.
        ///   - guides: A list of guides to apply to this property.
        public init<Value>(name: String, description: String? = nil, type: Value?.Type, guides: [GenerationGuide<Value>] = []) where Value : Generable

        /// Create a property that contains a string type.
        ///
        /// - Parameters:
        ///   - name: The property's name.
        ///   - description: A natural language description of what content
        ///     should be generated for this property.
        ///   - type: The type this property represents.
        ///   - guides: An array of regexes to be applied to this string. If there're multiple regexes in the array, only the last one will be applied.
        public init<RegexOutput>(name: String, description: String? = nil, type: String.Type, guides: [Regex<RegexOutput>] = [])

        /// Create an optional property that contains a generable type.
        ///
        /// - Parameters:
        ///   - name: The property's name.
        ///   - description: A natural language description of what content
        ///     should be generated for this property.
        ///   - type: The type this property represents.
        ///   - guides: An array of regexes to be applied to this string. If there're multiple regexes in the array, only the last one will be applied.
        public init<RegexOutput>(name: String, description: String? = nil, type: String?.Type, guides: [Regex<RegexOutput>] = [])
    }

    /// A string representation of the debug description.
    ///
    /// This string is not localized and is not appropriate for display to end users.
    public var debugDescription: String { get }

    /// Creates a schema by providing an array of properties.
    /// 
    /// - Parameters:
    ///   - type: The type this schema represents.
    ///   - description: A natural language description of this schema.
    ///   - properties: An array of properties.
    public init(type: any Generable.Type, description: String? = nil, properties: [GenerationSchema.Property])

    /// Creates a schema for a string enumeration.
    ///
    /// - Parameters:
    ///   - type: The type this schema represents.
    ///   - description: A natural language description of this schema.
    ///   - anyOf: The allowed choices.
    public init(type: any Generable.Type, description: String? = nil, anyOf choices: [String])

    /// Creates a schema as the union of several other types.
    ///
    /// - Parameters:
    ///   - type: The type this schema represents.
    ///   - description: A natural language description of this schema.
    ///   - anyOf: The types this schema should be a union of.
    public init(type: any Generable.Type, description: String? = nil, anyOf types: [any Generable.Type])

    /// Creates a schema by providing an array of dynamic schemas.
    ///
    /// - Parameters:
    ///   - root: The root schema.
    ///   - dependencies: An array of dynamic schemas.
    /// - Throws: Throws there are schemas with naming conflicts or
    ///   references to undefined types.
    public init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws

    /// A error that occurs when there is a problem creating a generation schema.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum SchemaError : Error, LocalizedError {

        /// The context in which the error occurred.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public struct Context : Sendable {

            /// A string representation of the debug description.
            ///
            /// This string is not localized and is not appropriate for display to end users.
            public let debugDescription: String

            /// The underlying errors that caused this error.
            public let underlyingErrors: [any Error]

            public init(debugDescription: String, underlyingErrors: [any Error] = [])
        }

        /// An error that represents an attempt to construct a schema from dynamic schemas,
        /// and two or more of the subschemas have the same type name.
        case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)

        /// An error that represents an attempt to construct a dynamic schema
        /// with properties that have conflicting names.
        case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)

        /// An error that represents an attempt to construct an anyOf schema with an
        /// empty array of type choices.
        case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)

        /// An error that represents an attempt to construct a schema from dynamic schemas,
        /// and one of those schemas references an undefined schema.
        case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)

        /// A string representation of the error description.
        public var errorDescription: String { get }

        /// A suggestion that indicates how to handle the error.
        public var recoverySuggestion: String? { get }
    }
}

/// Allows for influencing the allowed values of properties of a generable type.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@attached(peer) public macro Guide<T>(description: String? = nil, _ guides: GenerationGuide<T>...) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro") where T : Generable

/// Allows for influencing the allowed values of properties of a generable type.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@attached(peer) public macro Guide<RegexOutput>(description: String? = nil, _ guides: Regex<RegexOutput>) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")

/// Allows for influencing the allowed values of properties of a generable type.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@attached(peer) public macro Guide(description: String) = #externalMacro(module: "FoundationModelsMacros", type: "GuideMacro")

/// A structure that represents instructions.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Instructions {

    /// Creates an instance with the content you specify.
    public init(_ content: some InstructionsRepresentable)
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Instructions : InstructionsRepresentable {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Instructions {

    public init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows
}

/// A type that represents an instructions builder.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@resultBuilder public struct InstructionsBuilder {

    /// Creates a builder with the a block.
    public static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I : InstructionsRepresentable

    /// Creates a builder with the an array of prompts.
    public static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions

    /// Creates a builder with the first component.
    public static func buildEither(first component: some InstructionsRepresentable) -> Instructions

    /// Creates a builder with the second component.
    public static func buildEither(second component: some InstructionsRepresentable) -> Instructions

    /// Creates a builder with an optional component.
    public static func buildOptional(_ instructions: Instructions?) -> Instructions

    /// Creates a builder with a limited availability prompt.
    public static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions

    /// Creates a builder with an expression.
    public static func buildExpression<I>(_ expression: I) -> I where I : InstructionsRepresentable

    /// Creates a builder with a prompt expression.
    public static func buildExpression(_ expression: Instructions) -> Instructions
}

/// Conforming types represent instructions.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol InstructionsRepresentable {

    /// An instance that represents the instructions.
    @InstructionsBuilder var instructionsRepresentation: Instructions { get }
}

/// Feedback appropriate for attaching to Feedback Assistant.
///
/// Use this type to build out user feedback experiences
/// in your app. After collecting feedback, serialize
/// them into a JSONL file and submit it to Apple using Feedback
/// Assistant.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct LanguageModelFeedbackAttachment : Sendable, Encodable {

    /// Creates feedback from a person regarding a single transcript.
    ///
    /// Typically each output will contain a single transcript entry
    /// representing the model's response. The exception is for tool
    /// calling, where one example will contain three or more entries
    /// representing tool calls, tool outputs, and the final response.
    ///
    /// - Parameters:
    ///   - input: Transcript entries containing previous prompts and responses.
    ///   - output: Transcript entries containing model output.
    ///   - sentiment: An optional sentiment about the model's output.
    ///   - issues: Issues regarding the model's response.
    ///   - desiredOutputExamples: Examples of desired outputs.
    public init(input: [Transcript.Entry], output: [Transcript.Entry], sentiment: LanguageModelFeedbackAttachment.Sentiment?, issues: [LanguageModelFeedbackAttachment.Issue] = [], desiredOutputExamples: [[Transcript.Entry]] = [])

    /// Creates feedback from a person that indicates their preference
    /// among several outputs generated for the same input.
    ///
    /// Typically each output will contain a single transcript entry
    /// representing the model's response. The exception is for tool
    /// calling, where one example will contain three or more entries
    /// representing tool calls, tool outputs, and the final response.
    ///
    /// - Parameters:
    ///   - input: Transcript entries containing previous prompts and responses.
    ///   - outputs: Transcript entries for several candidate outputs.
    ///   - preferredOutputInex: The index of the output the user indicated preference for.
    ///   - explanation: An optional explanation from the user about their choice.
    public init(input: [Transcript.Entry], outputs: [[Transcript.Entry]], preferredOutputIndex: Array<[Transcript.Entry]>.Index, explanation: String? = nil)

    /// A sentiment regarding the model's response.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum Sentiment : Sendable, CaseIterable {

        /// A positive sentiment
        case positive

        /// A negative sentiment
        case negative

        /// A neutral sentiment
        case neutral

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: LanguageModelFeedbackAttachment.Sentiment, b: LanguageModelFeedbackAttachment.Sentiment) -> Bool

        /// A type that can represent a collection of all values of this type.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias AllCases = [LanguageModelFeedbackAttachment.Sentiment]

        /// A collection of all values of this type.
        nonisolated public static var allCases: [LanguageModelFeedbackAttachment.Sentiment] { get }

        /// Hashes the essential components of this value by feeding them into the
        /// given hasher.
        ///
        /// Implement this method to conform to the `Hashable` protocol. The
        /// components used for hashing must be the same as the components compared
        /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
        /// with each of these components.
        ///
        /// - Important: In your implementation of `hash(into:)`,
        ///   don't call `finalize()` on the `hasher` instance provided,
        ///   or replace it with a different instance.
        ///   Doing so may become a compile-time error in the future.
        ///
        /// - Parameter hasher: The hasher to use when combining the components
        ///   of this instance.
        public func hash(into hasher: inout Hasher)

        /// The hash value.
        ///
        /// Hash values are not guaranteed to be equal across different executions of
        /// your program. Do not save hash values to use during a future execution.
        ///
        /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
        ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
        ///   The compiler provides an implementation for `hashValue` for you.
        public var hashValue: Int { get }
    }

    /// An issue with the model's response.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Issue : Sendable {

        /// Categories for model response issues.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public enum Category : Sendable, CaseIterable {

            /// The response was not unhelpful.
            ///
            /// An unhelpful issue might be where you asked for a recipe, and the model gave you a list of
            /// ingredients but not amounts.
            case unhelpful

            /// The response was too verbose.
            ///
            /// A verbose issue might be where you asked for a simple recipe, and the model wrote introductory
            /// and conclusion paragraphs.
            case tooVerbose

            /// The model did not follow instructions correctly.
            ///
            /// An instruction issue might be where you asked for a recipe in numbered steps, and the model
            /// provided a recipe but didn't number the steps.
            case didNotFollowInstructions

            /// The model provided an incorrect response.
            ///
            /// An incorrect issue might be where you asked how to make a pizza, and the model suggested using glue.
            case incorrect

            /// The model exhibited bias or perpetuated a sterotype.
            ///
            /// A stereotype or bias issue might be where you ask the model to summarize an article written by
            /// a male, and the model doesn't state the authors sex, but the model uses male pronouns.
            case stereotypeOrBias

            /// The model produces suggestive or sexual material.
            ///
            /// A suggestive or sexual issue might be where you ask the model to draft a script for a school
            /// play, and it includes a sex scene.
            case suggestiveOrSexual

            /// The model produces vulgar or offensive material.
            ///
            /// A vulgar or offensive issue might be where you ask the model to draft a complaint about poor
            /// customer service, and it uses profanity.
            case vulgarOrOffensive

            /// The model throws a guardrail violation when it shouldn't.
            ///
            /// An unexpected guardrail issue might be where you ask for a cake recipe, and the framework
            /// throws a guardrail violation error.
            case triggeredGuardrailUnexpectedly

            /// Returns a Boolean value indicating whether two values are equal.
            ///
            /// Equality is the inverse of inequality. For any values `a` and `b`,
            /// `a == b` implies that `a != b` is `false`.
            ///
            /// - Parameters:
            ///   - lhs: A value to compare.
            ///   - rhs: Another value to compare.
            public static func == (a: LanguageModelFeedbackAttachment.Issue.Category, b: LanguageModelFeedbackAttachment.Issue.Category) -> Bool

            /// A type that can represent a collection of all values of this type.
            @available(iOS 26.0, macOS 26.0, *)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            public typealias AllCases = [LanguageModelFeedbackAttachment.Issue.Category]

            /// A collection of all values of this type.
            nonisolated public static var allCases: [LanguageModelFeedbackAttachment.Issue.Category] { get }

            /// Hashes the essential components of this value by feeding them into the
            /// given hasher.
            ///
            /// Implement this method to conform to the `Hashable` protocol. The
            /// components used for hashing must be the same as the components compared
            /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
            /// with each of these components.
            ///
            /// - Important: In your implementation of `hash(into:)`,
            ///   don't call `finalize()` on the `hasher` instance provided,
            ///   or replace it with a different instance.
            ///   Doing so may become a compile-time error in the future.
            ///
            /// - Parameter hasher: The hasher to use when combining the components
            ///   of this instance.
            public func hash(into hasher: inout Hasher)

            /// The hash value.
            ///
            /// Hash values are not guaranteed to be equal across different executions of
            /// your program. Do not save hash values to use during a future execution.
            ///
            /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
            ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
            ///   The compiler provides an implementation for `hashValue` for you.
            public var hashValue: Int { get }
        }

        /// Creates a new issue
        ///
        /// - Parameters:
        ///   - category: A category for this issue.
        ///   - explanation: An optional explanation of this issue.
        public init(category: LanguageModelFeedbackAttachment.Issue.Category, explanation: String? = nil)
    }

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: any Encoder) throws
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelFeedbackAttachment.Sentiment : Equatable {
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelFeedbackAttachment.Sentiment : Hashable {
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelFeedbackAttachment.Issue.Category : Equatable {
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelFeedbackAttachment.Issue.Category : Hashable {
}

/// An object that represents a session that interacts with a language model.
///
/// A session is a single context that you use to generate content with, and maintains
/// state between requests. You can reuse the existing instance or create a new one
/// each time you call the model. When you create a session you can provide instructions
/// that tells the model what its role is and provides guidance on how to respond.
///
/// ```swift
/// let instructions = """
///     You are a motivational workout coach that provides quotes to inspire
///     and motivate athletes.
///     """
///
/// let session = LanguageModelSession(instructions: instructions)
/// let prompt = "Generate a motivational quote for my next workout."
/// let response = try await session.respond(to: prompt)
/// ```
///
/// The framework records each call to the model in a ``Transcript`` that includes
/// all prompts and responses. If your session exceeds the available context size, it
/// throws an ``LanguageModelSession/GenerationError/exceededContextWindowSize(_:)``
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final public class LanguageModelSession {

    /// Controls the safety guardrails for prompt and response filtering.
    ///
    /// The default is the `system` level, which enables Apple guardrails that
    /// filter unsafe prompts and responses.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Guardrails : Sendable {

        /// A type that indicates the system provides the guardrails.
        public static let `default`: LanguageModelSession.Guardrails
    }

    /// A full history of interactions, including user inputs and model responses.
    final public var transcript: Transcript { get }

    /// A Boolean value that indicates a response is being generated.
    ///
    /// - Important: Attempting to call any of the respond methods while
    /// this property is `true` is a programmer error.
    final public var isResponding: Bool { get }

    /// Start a new session in blank slate state with string-based instructions.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - guardrails: Controls the guardrails setting for prompt and response filtering. System guardrails is enabled if not specified.
    ///   - tools: Tools to make available to the model for this session.
    ///   - instructions: Instructions that control the model's behavior.
    public convenience init(model: SystemLanguageModel = .default, guardrails: LanguageModelSession.Guardrails = .default, tools: [any Tool] = [], instructions: String? = nil)

    /// Start a new session in blank slate state with instructions builder.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - guardrails: Controls the guardrails setting for prompt and response filtering. System guardrails is enabled if not specified.
    ///   - tools: Tools to make available to the model for this session.
    ///   - instructions: Instructions that control the model's behavior.
    public convenience init(model: SystemLanguageModel = .default, guardrails: LanguageModelSession.Guardrails = .default, tools: [any Tool] = [], @InstructionsBuilder instructions: () throws -> Instructions) rethrows

    /// Start a new session in blank slate state with instructions.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - guardrails: Controls the guardrails setting for prompt and response filtering. System guardrails is enabled if not specified.
    ///   - tools: Tools to make available to the model for this session.
    ///   - instructions: Instructions that control the model's behavior.
    public convenience init(model: SystemLanguageModel = .default, guardrails: LanguageModelSession.Guardrails = .default, tools: [any Tool] = [], instructions: Instructions? = nil)

    /// Start a session by rehydrating from a transcript.
    ///
    /// - Parameters
    ///   - model: The language model to use for this session.
    ///   - guardrails: Controls the guardrails setting for prompt and response filtering. System guardrails is enabled if not specified.
    ///   - transcript: A transcript to resume from.
    ///   - tools: Tools to make available to the model for this session.
    public convenience init(model: SystemLanguageModel = .default, guardrails: LanguageModelSession.Guardrails = .default, tools: [any Tool] = [], transcript: Transcript)

    /// Requests that the system eagerly load the resources required for this session into memory.
    ///
    /// Consider calling this method when you need to immediately use the session.
    ///
    /// - Note: Calling this method does not guarantee that the system loads your assets immediately,
    /// particularly if your app is running in the background or the system is under load.
    final public func prewarm()

    /// A structure that stores the output of a response call.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Response<Content> {

        /// The response content.
        public let content: Content

        /// The list of transcript entries.
        public let transcriptEntries: ArraySlice<Transcript.Entry>
    }

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: GenerationOptions that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @discardableResult
    final public func respond(to prompt: Prompt, options: GenerationOptions = GenerationOptions(), isolation: isolated (any Actor)? = #isolation) async throws -> sending LanguageModelSession.Response<String>

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - options: GenerationOptions that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @discardableResult
    final public func respond(to prompt: String, options: GenerationOptions = GenerationOptions(), isolation: isolated (any Actor)? = #isolation) async throws -> sending LanguageModelSession.Response<String>

    /// Produces a response to a prompt.
    ///
    /// - Parameters:
    ///   - options: GenerationOptions that control how tokens are sampled from the distribution the model produces.
    ///   - prompt: A prompt for the model to respond to.
    /// - Returns: A string composed of the tokens produced by sampling model output.
    @discardableResult
    final public func respond(options: GenerationOptions = GenerationOptions(), isolation: isolated (any Actor)? = #isolation, @PromptBuilder prompt: () throws -> Prompt) async throws -> sending LanguageModelSession.Response<String>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    final public func respond(to prompt: Prompt, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), isolation: isolated (any Actor)? = #isolation) async throws -> sending LanguageModelSession.Response<GeneratedContent>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    final public func respond(to prompt: String, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), isolation: isolated (any Actor)? = #isolation) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generated content type as a response to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - prompt: A prompt for the model to respond to.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    final public func respond(options: GenerationOptions = GenerationOptions(), schema: GenerationSchema, includeSchemaInPrompt: Bool = true, isolation: isolated (any Actor)? = #isolation, @PromptBuilder prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    final public func respond<Content>(to prompt: Prompt, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), isolation: isolated (any Actor)? = #isolation) async throws -> sending LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: An instance of the `Generable` type.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    final public func respond<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions(), isolation: isolated (any Actor)? = #isolation) async throws -> sending LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a generable object as a response to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - prompt: A prompt for the model to respond to.
    /// - Returns: ``GeneratedContent`` containing the fields and values defined in the schema.
    @discardableResult
    final public func respond<Content>(generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), includeSchemaInPrompt: Bool = true, isolation: isolated (any Actor)? = #isolation, @PromptBuilder prompt: () throws -> Prompt) async throws -> sending LanguageModelSession.Response<Content> where Content : Generable

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    final public func streamResponse(to prompt: Prompt, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    @objc deinit
}

extension LanguageModelSession {

    /// An error that occurs while generating a response.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum GenerationError : Error, LocalizedError {

        /// The context in which the error occurred.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public struct Context : Sendable {

            /// A debug description to help developers diagnose issues during development.
            ///
            /// This string is not localized and is not appropriate for display to end users.
            public let debugDescription: String

            /// The underlying errors that caused this error.
            public let underlyingErrors: [any Error]

            /// Creates a context.
            ///
            /// - Parameters:
            ///   - debugDescription: The debug description to help developers diagnose issues during development.
            ///   - underlyingErrors: The underlying errors that caused this error.
            public init(debugDescription: String, underlyingErrors: [any Error] = [])
        }

        /// An error that indicates the transcript or a prompt exceeded the model's context window size.
        ///
        /// Start a new session or try again with a shorter prompt.
        case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)

        /// An error that indicates the assets required for the session are unavailable.
        ///
        /// This may happen if you forget to check model availability to begin with,
        /// or if the model assets are deleted. This can happen if the user disables
        /// AppleIntelligence while your app is running.
        ///
        /// You may be able to recover from this error by retrying later after the
        /// device has freed up enough space to redownload model assets.
        case assetsUnavailable(LanguageModelSession.GenerationError.Context)

        /// An error that indicates the system's safety guardrails are triggered by content in a
        /// prompt or the response generated by the model.
        case guardrailViolation(LanguageModelSession.GenerationError.Context)

        /// An error that indicates a generation guide with an unsupported pattern was used.
        case unsupportedGuide(LanguageModelSession.GenerationError.Context)

        /// An error that indicates an error that occurs if the model is prompted to respond in a language
        /// that it does not support.
        case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)

        /// An error that indicates the session failed to deserialize a valid generable type from model output.
        ///
        /// This can happen if generation was terminated early.
        case decodingFailure(LanguageModelSession.GenerationError.Context)

        /// A string representation of the error description.
        public var errorDescription: String { get }

        /// A string representation of the recovery suggestion.
        public var recoverySuggestion: String? { get }

        /// A string representation of the failure reason.
        public var failureReason: String? { get }
    }

    /// An error that occurs while a system language model is calling a tool.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct ToolCallError : Error, LocalizedError {

        /// The tool that produced the error.
        public var tool: any Tool

        /// The underlying error that was thrown during a tool call.
        public var underlyingError: any Error

        /// Creates a tool call error
        ///
        /// - Parameters:
        ///   - tool: The tool that produced the error.
        public init(tool: any Tool, underlyingError: any Error)

        /// A string representation of the error description.
        public var errorDescription: String? { get }
    }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession : @unchecked Sendable {
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession : Observable {
}

extension LanguageModelSession {

    /// A structure that  stores the output of a response stream.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct ResponseStream<Content> where Content : Generable {
    }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession {

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    final public func streamResponse(to prompt: String, schema: GenerationSchema, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - prompt: A prompt for the model to respond to.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    final public func streamResponse(options: GenerationOptions = GenerationOptions(), schema: GenerationSchema, includeSchemaInPrompt: Bool = true, @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    final public func streamResponse<Content>(to prompt: Prompt, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream to a prompt.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - type: A type to produce as the response.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    final public func streamResponse<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream for a type.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Parameters:
    ///   - type: A type to produce as the response.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    /// - Returns: A response stream.
    final public func streamResponse<Content>(generating type: Content.Type = Content.self, options: GenerationOptions = GenerationOptions(), includeSchemaInPrompt: Bool = true, @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

    /// Produces a response stream to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A specific prompt for the model to respond to.
    ///   - options: GenerationOptions that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces aggregated tokens.
    final public func streamResponse(to prompt: Prompt, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt.
    ///
    /// - Parameters:
    ///   - prompt: A specific prompt for the model to respond to.
    ///   - options: GenerationOptions that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces aggregated tokens.
    final public func streamResponse(to prompt: String, options: GenerationOptions = GenerationOptions()) -> sending LanguageModelSession.ResponseStream<String>

    /// Produces a response stream to a prompt.
    ///
    /// - Parameters:
    ///   - options: GenerationOptions that control how tokens are sampled from the distribution the model produces.
    ///   - prompt: A specific prompt for the model to respond to.
    /// - Returns: A response stream that produces aggregated tokens.
    final public func streamResponse(options: GenerationOptions = GenerationOptions(), @PromptBuilder prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension LanguageModelSession.ResponseStream : AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = Content.PartiallyGenerated

    /// The type of asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct AsyncIterator : AsyncIteratorProtocol {

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> LanguageModelSession.ResponseStream<Content>.Element?

        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias Element = LanguageModelSession.ResponseStream<Content>.Element
    }

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    public func makeAsyncIterator() -> LanguageModelSession.ResponseStream<Content>.AsyncIterator

    /// The result from a streaming response, after it completes.
    ///
    /// If the streaming response was finished successfully before calling
    /// `collect()`, this method `Response` returns immediately.
    ///
    /// If the streaming response was finished with an error before calling
    /// `collect()`, this method propagates that error.
    public func collect(isolation actor: isolated (any Actor)? = #isolation) async throws -> sending LanguageModelSession.Response<Content>
}

/// A structure that represents a prompt.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Prompt : Sendable {

    /// Creates an instance with the content you specify.
    public init(_ content: some PromptRepresentable)
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Prompt {

    public init(@PromptBuilder _ content: () throws -> Prompt) rethrows
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Prompt : PromptRepresentable {

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}

/// A type that represents a prompt builder.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@resultBuilder public struct PromptBuilder {

    /// Creates a builder with the a block.
    public static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P : PromptRepresentable

    /// Creates a builder with the an array of prompts.
    public static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt

    /// Creates a builder with the first component.
    public static func buildEither(first component: some PromptRepresentable) -> Prompt

    /// Creates a builder with the second component.
    public static func buildEither(second component: some PromptRepresentable) -> Prompt

    /// Creates a builder with an optional component.
    public static func buildOptional(_ component: Prompt?) -> Prompt

    /// Creates a builder with a limited availability prompt.
    public static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt

    /// Creates a builder with an expression.
    public static func buildExpression<P>(_ expression: P) -> P where P : PromptRepresentable

    /// Creates a builder with a prompt expression.
    public static func buildExpression(_ expression: Prompt) -> Prompt
}

/// A protocol that represents a prompt.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol PromptRepresentable {

    /// An instance that represents a prompt.
    @PromptBuilder var promptRepresentation: Prompt { get }
}

/// A probabilistic language model that is capable of completing prompts, following instructions, and using tools.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final public class SystemLanguageModel : Sendable {

    /// The availability of the language model.
    final public var availability: SystemLanguageModel.Availability { get }

    /// A convenience getter to check if the system is entirely ready.
    final public var isAvailable: Bool { get }

    /// A type that represents the use case for prompting.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct UseCase : Sendable, Equatable {

        /// A use case for general prompting.
        public static let general: SystemLanguageModel.UseCase

        /// A use case for content tagging.
        ///
        /// Content tagging produces a list of categorizing tags based on the input text. It can analyze input
        /// to detect topics, emotions, actions, and objects. For example, the input "I rode my bike to the store"
        /// might output an action tag "ride."
        ///
        /// - Note: Content tagging only supports English and can't be used with tool calling.
        public static let contentTagging: SystemLanguageModel.UseCase

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: SystemLanguageModel.UseCase, b: SystemLanguageModel.UseCase) -> Bool
    }

    @objc deinit
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// A type that represents an adapter for a language model.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Adapter {

        /// Values read from the creator defined field of the adapter's metadata.
        public let creatorDefinedMetadata: [String : Any]
    }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemLanguageModel {

    /// The availability status for a specific system language model.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @frozen public enum Availability : Equatable, Sendable {

        /// The unavailable reason.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public enum UnavailableReason : Equatable, Sendable {

            /// The device does not support Apple Intelligence.
            case deviceNotEligible

            /// Apple Intelligence is not enabled on the system.
            case appleIntelligenceNotEnabled

            /// The model(s) aren't available on the user's device.
            ///
            /// Models are downloaded automatically based on factors
            /// like network status, battery level, and system load.
            case modelNotReady

            /// Returns a Boolean value indicating whether two values are equal.
            ///
            /// Equality is the inverse of inequality. For any values `a` and `b`,
            /// `a == b` implies that `a != b` is `false`.
            ///
            /// - Parameters:
            ///   - lhs: A value to compare.
            ///   - rhs: Another value to compare.
            public static func == (a: SystemLanguageModel.Availability.UnavailableReason, b: SystemLanguageModel.Availability.UnavailableReason) -> Bool

            /// Hashes the essential components of this value by feeding them into the
            /// given hasher.
            ///
            /// Implement this method to conform to the `Hashable` protocol. The
            /// components used for hashing must be the same as the components compared
            /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
            /// with each of these components.
            ///
            /// - Important: In your implementation of `hash(into:)`,
            ///   don't call `finalize()` on the `hasher` instance provided,
            ///   or replace it with a different instance.
            ///   Doing so may become a compile-time error in the future.
            ///
            /// - Parameter hasher: The hasher to use when combining the components
            ///   of this instance.
            public func hash(into hasher: inout Hasher)

            /// The hash value.
            ///
            /// Hash values are not guaranteed to be equal across different executions of
            /// your program. Do not save hash values to use during a future execution.
            ///
            /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
            ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
            ///   The compiler provides an implementation for `hashValue` for you.
            public var hashValue: Int { get }
        }

        /// The system is ready for making requests.
        case available

        /// Indicates that the system is not ready for requests.
        case unavailable(SystemLanguageModel.Availability.UnavailableReason)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: SystemLanguageModel.Availability, b: SystemLanguageModel.Availability) -> Bool
    }

    /// The base version of the model.
    ///
    /// The base model is a generic model that is useful for a
    /// wide variety of applications, but is not specialized to
    /// any particular use case.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static let `default`: SystemLanguageModel

    /// Creates a system language model for a specific use case.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public convenience init(useCase: SystemLanguageModel.UseCase)

    /// Creates the base version of the model with an adapter.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public convenience init(adapter: SystemLanguageModel.Adapter)

    /// Languages supported by the model.
    final public var supportedLanguages: Set<Locale.Language> { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemLanguageModel : Observable {
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemLanguageModel.Adapter {

    /// Creates an adapter from the file URL.
    ///
    /// - Throws: An error of `AssetLoadingError` type when `fileURL`
    ///   is invalid.
    public init(fileURL: URL) throws

    /// Creates an adapter downloaded from the background assets framework.
    ///
    /// - Throws: An error of `AssetLoadingError` type when there are
    ///   no compatible asset packs with this adapter name downloaded.
    public init(name: String) throws

    /// Get all compatible adapter identifiers compatible with current system models.
    ///
    /// - Parameters:
    ///   - adapterName: Name of the adapter.
    ///
    /// - Returns: All adapter identifiers compatible with current system models, listed in descending
    ///   order in terms of system preference. You can determine which asset pack or on-demand
    ///   resource to download with compatible adapter identifiers.
    ///
    ///   On devices that support Apple Intelligence, the result is guaranteed to be non-empty.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static func compatibleAdapterIdentifiers(name: String) -> [String]

    /// Remove all obsolete adapters that are no longer compatible with current system models.
    public static func removeObsoleteAdapters()

    /// Returns true when an asset pack is an Foundation Models Adapter and compatible with current system base model.
    ///
    /// This compatibility check is designed to run before downloading the asset pack. It only performs
    /// validation on the asset pack name and metadata. ``SystemLanguageModel/init(adapterName:)``
    /// might still throw errors even if the corresponding asset pack is compatible.
    public static func isCompatible(_ assetPack: AssetPack) -> Bool
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SystemLanguageModel.Adapter {

    @available(iOS 26.0, macOS 26.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public enum AssetError : Error, LocalizedError {

        /// The context in which the error occurred.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public struct Context : Sendable {

            /// A debug description to help developers diagnose issues during development.
            /// 
            /// This string is not localized and is not appropriate for display to end users.
            public let debugDescription: String

            /// The underlying errors that caused this error.
            public let underlyingErrors: [any Error]

            public init(debugDescription: String, underlyingErrors: [any Error] = [])
        }

        /// An error that happens if the provided asset files are invalid.
        case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)

        /// An error that happens if the provided adapter name is invalid.
        case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)

        /// An error that happens if there are no compatible adapters for the current system base model.
        case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)

        /// A string representation of the error description.
        public var errorDescription: String { get }

        /// A localized message describing how one might recover from the failure.
        public var recoverySuggestion: String? { get }
    }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemLanguageModel.Availability.UnavailableReason : Hashable {
}

/// A tool that a model can call to gather information at runtime or perform side effects.
///
/// Tool calling gives the model the ability to call your code to incorporate
/// up-to-date information like recent events and data from your app. A tool
/// includes a name and a description that the framework puts in the prompt to let
/// the model decide when and how often to call your tool.
///
/// ```swift
/// struct FindContacts: Tool {
///     let name = "findContacts"
///     let description = "Finds a specific number of contacts"
///
///     @Generable
///     struct Arguments {
///         @Guide(description: "The number of contacts to get", .range(1...10))
///         let count: Int
///     }
///
///     func call(arguments: Arguments) async throws -> ToolOutput {
///         var contacts: [CNContact] = []
///         // Fetch a number of contacts using the arguments.
///         return ToolOutput(contacts)
///     }
/// }
/// ```
///
/// Tools must conform to <doc://com.apple.documentation/documentation/swift/sendable>
/// so the framework can run them concurrently. If the model needs to pass the output
/// of one tool as the input to another, it executes back-to-back tool calls.
///
/// You control the life cycle of your tool, so you can track the state of it between
/// calls to the model. For example, you might store a list of database records that
/// you don't want to reuse between tool calls.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol Tool : Sendable {

    /// The arguments that this tool should accept.
    ///
    /// Typically arguments are either a ``Generable`` type or ``GeneratedContent.``
    associatedtype Arguments : ConvertibleFromGeneratedContent

    /// A unique name for the tool, such as "get_weather", "toggleDarkMode", or "search contacts".
    var name: String { get }

    /// A natural language description of when and how to use the tool.
    var description: String { get }

    /// A schema for the parameters this tool accepts.
    var parameters: GenerationSchema { get }

    /// If true, the model's name, description, and parameters schema will be injected
    /// into the instructions of sessions that leverage this tool.
    ///
    /// The default implementation is `true`
    ///
    /// - Note: This should only be `false` if the model has been trained to have
    /// innate knowledge of this tool. For zero-shot prompting, it should always be `true`.
    var includesSchemaInInstructions: Bool { get }

    /// A language model will call this method when it wants to leverage this tool.
    ///
    /// If errors are throw in the body of this method, they will be wrapped in a 
    /// ``LanguageModelSession.ToolCallError`` and rethrown at the call site
    /// of ``LanguageModelSession.respond(to:)``.
    ///
    /// - Note: This method may be invoked concurrently with itself or with other tools.
    func call(arguments: Self.Arguments) async throws -> ToolOutput
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Tool {

    /// A unique name for the tool, such as "get_weather", "toggleDarkMode", or "search contacts".
    public var name: String { get }

    /// If true, the model's name, description, and parameters schema will be injected
    /// into the instructions of sessions that leverage this tool.
    ///
    /// The default implementation is `true`
    ///
    /// - Note: This should only be `false` if the model has been trained to have
    /// innate knowledge of this tool. For zero-shot prompting, it should always be `true`.
    public var includesSchemaInInstructions: Bool { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Tool where Self.Arguments : Generable {

    /// A schema for the parameters this tool accepts.
    public var parameters: GenerationSchema { get }
}

/// A structure that contains the output a tool generates.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct ToolOutput : Sendable {

    /// Creates a tool output with a string you specify.
    public init(_ string: String)

    /// Creates a tool output with a generated encodable object.
    public init(_ content: GeneratedContent)
}

/// A transcript that documents interactions with a language model.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Transcript : Sendable, Equatable {

    /// A ordered list of entries, representing inputs to and outputs from the model.
    public var entries: [Transcript.Entry]

    /// Creates a transcript.
    ///
    /// - Parameters:
    ///   - entries: An array of entries to seed the transcript.
    public init(entries: [Transcript.Entry] = [])

    /// An entry in a transcript.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum Entry : Sendable, Identifiable, Equatable {

        /// Instructions, typically provided by you, the developer.
        case instructions(Transcript.Instructions)

        /// A prompt, typically sourced from an end user.
        case prompt(Transcript.Prompt)

        /// A tool call containing a tool name and the arguments to invoke it with.
        case toolCalls(Transcript.ToolCalls)

        /// An tool output provided back to the model.
        case toolOutput(Transcript.ToolOutput)

        /// A response from the model.
        case response(Transcript.Response)

        /// The stable identity of the entity associated with this instance.
        public var id: String { get }

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Entry, b: Transcript.Entry) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// The types of segments that may be included in a transcript entry.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum Segment : Sendable, Identifiable, Equatable {

        /// A segment containing text.
        case text(Transcript.TextSegment)

        /// A segment containing structured content
        case structure(Transcript.StructuredSegment)

        /// The stable identity of the entity associated with this instance.
        public var id: String { get }

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Segment, b: Transcript.Segment) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// A segment containing text.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct TextSegment : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        public var content: String

        public init(id: String = UUID().uuidString, content: String)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.TextSegment, b: Transcript.TextSegment) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// A segment containing structured content.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct StructuredSegment : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// A source that be used to understand which type content represents.
        public var source: String

        /// The content of the segment.
        public let content: GeneratedContent

        public init(id: String = UUID().uuidString, source: String, content: GeneratedContent)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.StructuredSegment, b: Transcript.StructuredSegment) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// Instructions provided to the model that define its behavior.
    ///
    /// Instructions are typically provided by you the developer to define
    /// the desired role and behavior of the model.
    ///
    /// The model is trained to obey instructions over any commands it
    /// receives in prompts. This is a security mechanism to mitigate prompt
    /// injection attacks, but it is not bullet proof by any means.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Instructions : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// The content of the instructions, in natural language.
        ///
        /// - Note: Instructions are often provided in English even when the
        /// users interact with the model in another language.
        public var segments: [Transcript.Segment]

        /// A list of tools made available to the model.
        public var toolDefinitions: [Transcript.ToolDefinition]

        /// Initialize instructions by describing how you want the model to
        /// behave using natural language.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for this instructions segment.
        ///   - segments: An array of segments that make up the instructions.
        ///   - toolDefinitions: Tools that the model should be allowed to call.
        public init(id: String = UUID().uuidString, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition])

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Instructions, b: Transcript.Instructions) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// A definition of a tool.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct ToolDefinition : Sendable, Equatable {

        /// The tool's name.
        public var name: String

        /// A description of how and when to use the tool.
        public var description: String

        public init(name: String, description: String, parameters: GenerationSchema)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ToolDefinition, b: Transcript.ToolDefinition) -> Bool
    }

    /// A prompt from the user asking the model.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Prompt : Sendable, Identifiable, Equatable {

        /// The identifier of the prompt.
        public var id: String

        /// Ordered prompt segments, often interleaved text and images.
        public var segments: [Transcript.Segment]

        /// Generation options associated with the prompt.
        public var options: GenerationOptions

        /// An optional response format that describes the desired output structure.
        public var responseFormat: Transcript.ResponseFormat?

        /// Creates a prompt.
        ///
        /// - Parameters:
        ///   - id: A ``Generable`` type to use as the response format.
        ///   - segments: An array of segments that make up the prompt.
        ///   - options: Options that control how tokens are sampled from the distribution the model produces.
        ///   - responseFormat: A response format that describes the output structure.
        public init(id: String = UUID().uuidString, segments: [Transcript.Segment], options: GenerationOptions = GenerationOptions(), responseFormat: Transcript.ResponseFormat? = nil)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Prompt, b: Transcript.Prompt) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// Specifies a response format that the model must conform its output to.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct ResponseFormat : Sendable, Equatable {

        /// A name associated with the response format.
        public var name: String { get }

        /// Creates a response format with type you specify.
        ///
        /// - Parameters:
        ///   - type: A ``Generable`` type to use as the response format.
        public init<Content>(type: Content.Type) where Content : Generable

        /// Creates a response format with a schema.
        ///
        /// - Parameters:
        ///   - schema: A schema to use as the response format.
        public init(schema: GenerationSchema)

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ResponseFormat, b: Transcript.ResponseFormat) -> Bool
    }

    /// A collection tool calls generated by the model.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct ToolCalls : Sendable, Identifiable, Equatable, RandomAccessCollection {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        public init<C>(id: String = UUID().uuidString, _ calls: C) where C : Collection, C.Element == Transcript.ToolCall

        /// Accesses the element at the specified position.
        ///
        /// The following example accesses an element of an array through its
        /// subscript to print its value:
        ///
        ///     var streets = ["Adams", "Bryant", "Channing", "Douglas", "Evarts"]
        ///     print(streets[1])
        ///     // Prints "Bryant"
        ///
        /// You can subscript a collection with any valid index other than the
        /// collection's end index. The end index refers to the position one past
        /// the last element of a collection, so it doesn't correspond with an
        /// element.
        ///
        /// - Parameter position: The position of the element to access. `position`
        ///   must be a valid index of the collection that is not equal to the
        ///   `endIndex` property.
        ///
        /// - Complexity: O(1)
        public subscript(position: Int) -> Transcript.ToolCall { get }

        /// The position of the first element in a nonempty collection.
        ///
        /// If the collection is empty, `startIndex` is equal to `endIndex`.
        public var startIndex: Int { get }

        /// The collection's "past the end" position---that is, the position one
        /// greater than the last valid subscript argument.
        ///
        /// When you need a range that includes the last element of a collection, use
        /// the half-open range operator (`..<`) with `endIndex`. The `..<` operator
        /// creates a range that doesn't include the upper bound, so it's always
        /// safe to use with `endIndex`. For example:
        ///
        ///     let numbers = [10, 20, 30, 40, 50]
        ///     if let index = numbers.firstIndex(of: 30) {
        ///         print(numbers[index ..< numbers.endIndex])
        ///     }
        ///     // Prints "[30, 40, 50]"
        ///
        /// If the collection is empty, `endIndex` is equal to `startIndex`.
        public var endIndex: Int { get }

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ToolCalls, b: Transcript.ToolCalls) -> Bool

        /// A type representing the sequence's elements.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias Element = Transcript.ToolCall

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String

        /// A type that represents a position in the collection.
        ///
        /// Valid indices consist of the position of every element and a
        /// "past the end" position that's not valid for use as a subscript
        /// argument.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias Index = Int

        /// A type that represents the indices that are valid for subscripting the
        /// collection, in ascending order.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias Indices = Range<Int>

        /// A type that provides the collection's iteration interface and
        /// encapsulates its iteration state.
        ///
        /// By default, a collection conforms to the `Sequence` protocol by
        /// supplying `IndexingIterator` as its associated `Iterator`
        /// type.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias Iterator = IndexingIterator<Transcript.ToolCalls>

        /// A collection representing a contiguous subrange of this collection's
        /// elements. The subsequence shares indices with the original collection.
        ///
        /// The default subsequence type for collections that don't define their own
        /// is `Slice`.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias SubSequence = Slice<Transcript.ToolCalls>
    }

    /// A tool call generated by the model containing the name of a tool and arguments to pass to it.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct ToolCall : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// The name of the tool being invoked.
        public var toolName: String

        /// Arguments to pass to the invoked tool.
        public var arguments: GeneratedContent

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ToolCall, b: Transcript.ToolCall) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// A tool output provided back to the model.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct ToolOutput : Sendable, Identifiable, Equatable {

        /// A unique id for this tool output.
        public var id: String

        /// The name of the tool that produced this output.
        public var toolName: String

        /// Segments of the tool output.
        public var segments: [Transcript.Segment]

        public init(id: String, toolName: String, segments: [Transcript.Segment])

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.ToolOutput, b: Transcript.ToolOutput) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// A response from the model.
    @available(iOS 26.0, macOS 26.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Response : Sendable, Identifiable, Equatable {

        /// The stable identity of the entity associated with this instance.
        public var id: String

        /// Version aware identifiers for all assets used to generate this response.
        public var assetIDs: [String]

        /// Ordered prompt segments, often interleaved text and images.
        public var segments: [Transcript.Segment]

        public init(id: String = UUID().uuidString, assetIDs: [String], segments: [Transcript.Segment])

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Transcript.Response, b: Transcript.Response) -> Bool

        /// A type representing the stable identity of the entity associated with
        /// an instance.
        @available(iOS 26.0, macOS 26.0, *)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public typealias ID = String
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: Transcript, b: Transcript) -> Bool
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript : Codable {

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: any Encoder) throws
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.Entry : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.Segment : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.TextSegment : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.StructuredSegment : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.Instructions : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.Prompt : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.ResponseFormat : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.ToolCalls : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.ToolCall : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.ToolOutput : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension Transcript.Response : CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension String : InstructionsRepresentable {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Array : InstructionsRepresentable where Element : InstructionsRepresentable {

    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension String : PromptRepresentable {

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Array : PromptRepresentable where Element : PromptRepresentable {

    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Optional where Wrapped : Generable {

    public typealias PartiallyGenerated = Wrapped.PartiallyGenerated
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Optional : ConvertibleToGeneratedContent, PromptRepresentable, InstructionsRepresentable where Wrapped : ConvertibleToGeneratedContent {

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Bool : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension String : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Int : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Float : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Double : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Decimal : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Array : Generable where Element : Generable {

    /// A representation of partially generated content
    public typealias PartiallyGenerated = [Element.PartiallyGenerated]

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Array : ConvertibleToGeneratedContent where Element : ConvertibleToGeneratedContent {

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Array : ConvertibleFromGeneratedContent where Element : ConvertibleFromGeneratedContent {

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Never : Generable {

    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema { get }

    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws

    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent { get }
}

