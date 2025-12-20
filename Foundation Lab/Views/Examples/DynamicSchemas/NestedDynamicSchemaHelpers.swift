//
//  NestedDynamicSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension NestedDynamicSchemaView {
    func schemaVisualization(for index: Int) -> String {
        switch index {
        case 0:
            return """
            Company
            ├── name: String
            ├── headquarters: Location
            │   ├── city: String
            │   └── state: String
            ├── ceo: Person
            │   ├── name: String
            │   └── startYear: Int
            └── departments: [Department]
                ├── name: String
                └── head: String
            """
        case 1:
            return """
            Order
            ├── orderNumber: String
            ├── date: String
            ├── customer: Customer
            │   └── name: String
            ├── items: [OrderItem]
            │   ├── name: String
            │   ├── quantity: Int
            │   └── price: Float
            ├── shipping: ShippingInfo
            │   └── address: Address
            └── payment: PaymentInfo
            """
        default:
            return """
            Event
            ├── name: String
            ├── venue: Venue
            │   ├── name: String
            │   └── location: String
            ├── dates: DateRange
            │   ├── start: String
            │   └── end: String
            └── sessions: [Session]
                ├── title: String
                └── speaker: Speaker
            """
        }
    }

    var exampleCode: String {
        """
        // Creating deeply nested schemas
        let addressSchema = DynamicGenerationSchema(
            name: "Address",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "street",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "city",
                    schema: .init(type: String.self)
                )
            ]
        )

        let personSchema = DynamicGenerationSchema(
            name: "Person",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "address",
                    schema: addressSchema  // Nested object
                )
            ]
        )

        // Arrays of nested objects
        let teamSchema = DynamicGenerationSchema(
            name: "Team",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "members",
                    schema: .init(arrayOf: personSchema)
                )
            ]
        )

        // Register all schemas as dependencies
        let schema = try GenerationSchema(
            root: teamSchema,
            dependencies: [addressSchema, personSchema]
        )
        """
    }

    private func createLocationSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Location",
            description: "A geographic location",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "city",
                    description: "City name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "state",
                    description: "State or region",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )
    }

    private func createCompanyPersonSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Person",
            description: "Information about a person",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Person's full name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "startYear",
                    description: "Year they started",
                    schema: .init(type: Int.self),
                    isOptional: true
                )
            ]
        )
    }

    private func createDepartmentSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Department",
            description: "Company department",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Department name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "head",
                    description: "Department head name",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )
    }

    func createCompanySchema() throws -> GenerationSchema {
        let locationSchema = createLocationSchema()
        let personSchema = createCompanyPersonSchema()
        let departmentSchema = createDepartmentSchema()

        let companySchema = DynamicGenerationSchema(
            name: "Company",
            description: "Company information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Company name",
                    schema: .init(type: String.self)
                ),
                DynamicSchemaHelpers.nestedProperty(
                    "headquarters",
                    schema: locationSchema,
                    description: "Company headquarters location"
                ),
                DynamicSchemaHelpers.nestedProperty(
                    "ceo",
                    schema: personSchema,
                    description: "Chief Executive Officer"
                ),
                DynamicGenerationSchema.Property(
                    name: "foundedYear",
                    description: "Year company was founded",
                    schema: .init(type: Int.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "employeeCount",
                    description: "Number of employees",
                    schema: .init(type: Int.self),
                    isOptional: true
                ),
                DynamicSchemaHelpers.arrayProperty(
                    "departments",
                    elementSchema: departmentSchema,
                    description: "List of departments",
                    isOptional: true
                )
            ]
        )

        return try GenerationSchema(
            root: companySchema,
            dependencies: [locationSchema, personSchema, departmentSchema]
        )
    }

    private func createCustomerSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Customer",
            properties: [
                DynamicSchemaHelpers.typedProperty("name", type: String.self)
            ]
        )
    }

    private func createOrderItemSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "OrderItem",
            properties: [
                DynamicSchemaHelpers.typedProperty("name", type: String.self, description: "Item name"),
                DynamicSchemaHelpers.typedProperty("quantity", type: Int.self),
                DynamicSchemaHelpers.typedProperty("price", type: Float.self)
            ]
        )
    }

    private func createOrderAddressSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Address",
            properties: [
                DynamicSchemaHelpers.typedProperty("street", type: String.self),
                DynamicSchemaHelpers.typedProperty("city", type: String.self),
                DynamicSchemaHelpers.typedProperty("state", type: String.self),
                DynamicSchemaHelpers.typedProperty("zip", type: String.self)
            ]
        )
    }

    private func createShippingSchema(addressSchema: DynamicGenerationSchema) -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "ShippingInfo",
            properties: [
                DynamicSchemaHelpers.nestedProperty("address", schema: addressSchema),
                DynamicGenerationSchema.Property(name: "method", schema: .init(type: String.self), isOptional: true)
            ]
        )
    }

    private func createPaymentSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "PaymentInfo",
            properties: [
                DynamicSchemaHelpers.typedProperty("method", type: String.self),
                DynamicSchemaHelpers.typedProperty("lastFour", type: String.self, isOptional: true)
            ]
        )
    }

    func createOrderSchema() throws -> GenerationSchema {
        let customerSchema = createCustomerSchema()
        let orderItemSchema = createOrderItemSchema()
        let addressSchema = createOrderAddressSchema()
        let shippingSchema = createShippingSchema(addressSchema: addressSchema)
        let paymentSchema = createPaymentSchema()

        let orderSchema = DynamicGenerationSchema(
            name: "Order",
            properties: [
                DynamicGenerationSchema.Property(name: "orderNumber", schema: .init(type: String.self)),
                DynamicGenerationSchema.Property(name: "date", schema: .init(type: String.self)),
                DynamicSchemaHelpers.nestedProperty("customer", schema: customerSchema),
                DynamicSchemaHelpers.arrayProperty("items", elementSchema: orderItemSchema),
                DynamicSchemaHelpers.nestedProperty("shipping", schema: shippingSchema),
                DynamicSchemaHelpers.nestedProperty("payment", schema: paymentSchema)
            ]
        )

        return try GenerationSchema(
            root: orderSchema,
            dependencies: [customerSchema, orderItemSchema, addressSchema, shippingSchema, paymentSchema]
        )
    }

    private func createVenueSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Venue",
            properties: [
                DynamicSchemaHelpers.typedProperty("name", type: String.self),
                DynamicSchemaHelpers.typedProperty("location", type: String.self)
            ]
        )
    }

    private func createDateRangeSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "DateRange",
            properties: [
                DynamicSchemaHelpers.typedProperty("start", type: String.self),
                DynamicSchemaHelpers.typedProperty("end", type: String.self)
            ]
        )
    }

    private func createSpeakerSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Speaker",
            properties: [
                DynamicSchemaHelpers.typedProperty("name", type: String.self),
                DynamicSchemaHelpers.typedProperty("affiliation", type: String.self, isOptional: true)
            ]
        )
    }

    private func createSessionSchema(speakerSchema: DynamicGenerationSchema) -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Session",
            properties: [
                DynamicGenerationSchema.Property(name: "title", schema: .init(type: String.self)),
                DynamicSchemaHelpers.nestedProperty("speaker", schema: speakerSchema)
            ]
        )
    }

    func createEventSchema() throws -> GenerationSchema {
        let venueSchema = createVenueSchema()
        let dateRangeSchema = createDateRangeSchema()
        let speakerSchema = createSpeakerSchema()
        let sessionSchema = createSessionSchema(speakerSchema: speakerSchema)

        let eventSchema = DynamicGenerationSchema(
            name: "Event",
            properties: [
                DynamicGenerationSchema.Property(name: "name", schema: .init(type: String.self)),
                DynamicSchemaHelpers.nestedProperty("venue", schema: venueSchema),
                DynamicSchemaHelpers.nestedProperty("dates", schema: dateRangeSchema),
                DynamicSchemaHelpers.arrayProperty("sessions", elementSchema: sessionSchema, isOptional: true),
                DynamicGenerationSchema.Property(name: "registrationPrice", schema: .init(type: Float.self), isOptional: true)
            ]
        )

        return try GenerationSchema(
            root: eventSchema,
            dependencies: [venueSchema, dateRangeSchema, speakerSchema, sessionSchema]
        )
    }
}
