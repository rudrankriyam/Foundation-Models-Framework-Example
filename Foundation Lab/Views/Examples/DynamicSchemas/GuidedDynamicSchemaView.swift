//
//  GuidedDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct GuidedDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var selectedGuideType = "Pattern Matching"
    @State private var generatedResults: [String] = []
    
    let guideTypes = [
        "Pattern Matching",
        "Number Ranges",
        "Array Constraints",
        "Complex Validation"
    ]
    
    var body: some View {
        ExampleViewBase(
            title: "Generation Guides",
            description: "Apply constraints to generated values using generation guides",
            defaultPrompt: "Generate data according to the selected guide type",
            currentPrompt: .constant("Generate data according to the selected guide type"),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: codeExample(for: selectedGuideType),
            onRun: { runExample() },
            onReset: { 
                executor.reset()
                generatedResults = []
            }
        ) {
            VStack(spacing: Spacing.medium) {
                // Guide Type Selector
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Select Guide Type")
                        .font(.headline)
                    
                    Picker("Guide Type", selection: $selectedGuideType) {
                        ForEach(guideTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedGuideType) { _ in
                        generatedResults = []
                        executor.reset()
                    }
                }
                .padding(.horizontal)
                
                // Guide Description
                GroupBox {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(guideDescription(for: selectedGuideType))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(guideExample(for: selectedGuideType))
                            .font(.system(.caption, design: .monospaced))
                            .padding(Spacing.small)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal)
                
                // Results
                if !generatedResults.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Results")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                ForEach(generatedResults, id: \.self) { result in
                                    Text(result)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(Spacing.small)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func runExample() {
        Task {
            do {
                generatedResults = []
                
                switch selectedGuideType {
                case "Pattern Matching":
                    try await runPatternExample()
                case "Number Ranges":
                    try await runNumberRangeExample()
                case "Array Constraints":
                    try await runArrayConstraintExample()
                case "Complex Validation":
                    try await runComplexValidationExample()
                default:
                    break
                }
            } catch {
                await MainActor.run {
                    executor.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func runPatternExample() async throws {
        struct ProductCode: Codable {
            let code: String
            let description: String
        }
        
        let schema = DynamicGenerationSchema(
            type: ProductCode.self,
            generateFor: \.code,
            guides: [
                .pattern(/[A-Z]{3}-\d{4}-[A-Z]/)
            ]
        )
        
        try await executor.execute(
            schema: schema,
            prompt: "Generate 5 product codes for electronic components",
            processResult: { (products: [ProductCode]) in
                generatedResults = products.map { 
                    "Code: \($0.code)\nDescription: \($0.description)"
                }
            }
        )
    }
    
    private func runNumberRangeExample() async throws {
        struct PriceRange: Codable {
            let product: String
            let price: Double
            let quantity: Int
        }
        
        let schema = DynamicGenerationSchema(
            type: PriceRange.self,
            guides: [
                DynamicGenerationSchema.Guide(
                    keyPath: \PriceRange.price,
                    guide: .range(19.99...199.99)
                ),
                DynamicGenerationSchema.Guide(
                    keyPath: \PriceRange.quantity,
                    guide: .range(1...100)
                )
            ]
        )
        
        try await executor.execute(
            schema: schema,
            prompt: "Generate pricing for 5 office supplies",
            processResult: { (items: [PriceRange]) in
                generatedResults = items.map {
                    "\($0.product): $\(String(format: "%.2f", $0.price)) (Qty: \($0.quantity))"
                }
            }
        )
    }
    
    private func runArrayConstraintExample() async throws {
        struct TeamAssignment: Codable {
            let teamName: String
            let members: [String]
            let skills: [String]
        }
        
        let schema = DynamicGenerationSchema(
            type: TeamAssignment.self,
            guides: [
                DynamicGenerationSchema.Guide(
                    keyPath: \TeamAssignment.members,
                    guide: .arrayLength(3...5)
                ),
                DynamicGenerationSchema.Guide(
                    keyPath: \TeamAssignment.skills,
                    guide: .arrayLength(2...4)
                )
            ]
        )
        
        try await executor.execute(
            schema: schema,
            prompt: "Generate 3 software development teams",
            processResult: { (teams: [TeamAssignment]) in
                generatedResults = teams.map { team in
                    """
                    Team: \(team.teamName)
                    Members: \(team.members.joined(separator: ", "))
                    Skills: \(team.skills.joined(separator: ", "))
                    """
                }
            }
        )
    }
    
    private func runComplexValidationExample() async throws {
        struct UserAccount: Codable {
            let username: String
            let email: String
            let age: Int
            let accountType: String
        }
        
        let schema = DynamicGenerationSchema(
            type: UserAccount.self,
            guides: [
                DynamicGenerationSchema.Guide(
                    keyPath: \UserAccount.username,
                    guide: .pattern(/[a-z][a-z0-9_]{3,15}/)
                ),
                DynamicGenerationSchema.Guide(
                    keyPath: \UserAccount.email,
                    guide: .pattern(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)
                ),
                DynamicGenerationSchema.Guide(
                    keyPath: \UserAccount.age,
                    guide: .range(18...120)
                ),
                DynamicGenerationSchema.Guide(
                    keyPath: \UserAccount.accountType,
                    guide: .oneOf(["free", "premium", "enterprise"])
                )
            ]
        )
        
        try await executor.execute(
            schema: schema,
            prompt: "Generate 5 diverse user accounts",
            processResult: { (accounts: [UserAccount]) in
                generatedResults = accounts.map { account in
                    """
                    Username: \(account.username)
                    Email: \(account.email)
                    Age: \(account.age)
                    Type: \(account.accountType)
                    """
                }
            }
        )
    }
    
    private func guideDescription(for type: String) -> String {
        switch type {
        case "Pattern Matching":
            return "Use regular expressions to constrain string values"
        case "Number Ranges":
            return "Define minimum and maximum values for numeric properties"
        case "Array Constraints":
            return "Control the length and content of array properties"
        case "Complex Validation":
            return "Combine multiple guides for comprehensive validation"
        default:
            return ""
        }
    }
    
    private func guideExample(for type: String) -> String {
        switch type {
        case "Pattern Matching":
            return ".pattern(/[A-Z]{3}-\\d{4}-[A-Z]/)"
        case "Number Ranges":
            return ".range(19.99...199.99)"
        case "Array Constraints":
            return ".arrayLength(3...5)"
        case "Complex Validation":
            return ".oneOf([\"free\", \"premium\", \"enterprise\"])"
        default:
            return ""
        }
    }
    
    private func codeExample(for type: String) -> String {
        switch type {
        case "Pattern Matching":
            return """
            // Pattern matching for product codes
            struct ProductCode: Codable {
                let code: String
                let description: String
            }
            
            let schema = DynamicGenerationSchema(
                type: ProductCode.self,
                generateFor: \\.code,
                guides: [
                    .pattern(/[A-Z]{3}-\\d{4}-[A-Z]/)
                ]
            )
            
            // Generated codes will match: ABC-1234-X
            """
            
        case "Number Ranges":
            return """
            // Number ranges for pricing
            struct PriceRange: Codable {
                let product: String
                let price: Double
                let quantity: Int
            }
            
            let schema = DynamicGenerationSchema(
                type: PriceRange.self,
                guides: [
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.price,
                        guide: .range(19.99...199.99)
                    ),
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.quantity,
                        guide: .range(1...100)
                    )
                ]
            )
            """
            
        case "Array Constraints":
            return """
            // Array length constraints
            struct TeamAssignment: Codable {
                let teamName: String
                let members: [String]
                let skills: [String]
            }
            
            let schema = DynamicGenerationSchema(
                type: TeamAssignment.self,
                guides: [
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.members,
                        guide: .arrayLength(3...5)
                    ),
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.skills,
                        guide: .arrayLength(2...4)
                    )
                ]
            )
            """
            
        case "Complex Validation":
            return """
            // Multiple validation rules
            struct UserAccount: Codable {
                let username: String
                let email: String
                let age: Int
                let accountType: String
            }
            
            let schema = DynamicGenerationSchema(
                type: UserAccount.self,
                guides: [
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.username,
                        guide: .pattern(/[a-z][a-z0-9_]{3,15}/)
                    ),
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.email,
                        guide: .pattern(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}/)
                    ),
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.age,
                        guide: .range(18...120)
                    ),
                    DynamicGenerationSchema.Guide(
                        keyPath: \\.accountType,
                        guide: .oneOf(["free", "premium", "enterprise"])
                    )
                ]
            )
            """
            
        default:
            return ""
        }
    }
}

#Preview {
    NavigationStack {
        GuidedDynamicSchemaView()
    }
}