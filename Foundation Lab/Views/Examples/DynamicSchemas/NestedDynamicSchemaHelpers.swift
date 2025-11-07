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
                DynamicGenerationSchema.Property(
                    name: "headquarters",
                    description: "Company headquarters location",
                    schema: locationSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "ceo",
                    description: "Chief Executive Officer",
                    schema: personSchema
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
                DynamicGenerationSchema.Property(
                    name: "departments",
                    description: "List of departments",
                    schema: .init(arrayOf: departmentSchema),
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
        DynamicGenerationSchema(
            name: "Customer",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                )
            ]
        )
    }

    private func createOrderItemSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "OrderItem",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Item name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "quantity",
                    schema: .init(type: Int.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "price",
                    schema: .init(type: Float.self)
                )
            ]
        )
    }

    private func createOrderAddressSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Address",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "street",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "city",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "state",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "zip",
                    schema: .init(type: String.self)
                )
            ]
        )
    }

    private func createShippingSchema(addressSchema: DynamicGenerationSchema) -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "ShippingInfo",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "address",
                    schema: addressSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "method",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )
    }

    private func createPaymentSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "PaymentInfo",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "method",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "lastFour",
                    schema: .init(type: String.self),
                    isOptional: true
                )
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
                DynamicGenerationSchema.Property(
                    name: "orderNumber",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "date",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "customer",
                    schema: customerSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "items",
                    schema: .init(arrayOf: orderItemSchema)
                ),
                DynamicGenerationSchema.Property(
                    name: "shipping",
                    schema: shippingSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "payment",
                    schema: paymentSchema
                )
            ]
        )

        return try GenerationSchema(
            root: orderSchema,
            dependencies: [customerSchema, orderItemSchema, addressSchema, shippingSchema, paymentSchema]
        )
    }

    private func createVenueSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Venue",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "location",
                    schema: .init(type: String.self)
                )
            ]
        )
    }

    private func createDateRangeSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "DateRange",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "start",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "end",
                    schema: .init(type: String.self)
                )
            ]
        )
    }

    private func createSpeakerSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Speaker",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "affiliation",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )
    }

    private func createSessionSchema(speakerSchema: DynamicGenerationSchema) -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Session",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "title",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "speaker",
                    schema: speakerSchema
                )
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
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "venue",
                    schema: venueSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "dates",
                    schema: dateRangeSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "sessions",
                    schema: .init(arrayOf: sessionSchema),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "registrationPrice",
                    schema: .init(type: Float.self),
                    isOptional: true
                )
            ]
        )

        return try GenerationSchema(
            root: eventSchema,
            dependencies: [venueSchema, dateRangeSchema, speakerSchema, sessionSchema]
        )
    }
}
