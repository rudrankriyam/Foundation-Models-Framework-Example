//
//  ContactsTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import Contacts

/// `ContactsTool` provides access to the user's contacts.
///
/// This tool can search, read, and create contacts in the user's address book.
/// Important: This requires the Contacts entitlement and user permission.
struct ContactsTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "manageContacts"
  /// A brief description of the tool's functionality.
  let description = "Search, read, and create contacts in the address book"
  
  /// Arguments for contact operations.
  @Generable
  struct Arguments {
    /// The action to perform: "search", "read", "create"
    @Guide(description: "The action to perform: 'search', 'read', 'create'")
    var action: String
    
    /// Search query for finding contacts
    @Guide(description: "Search query for finding contacts (name, email, phone)")
    var query: String?
    
    /// Contact identifier for reading specific contact
    @Guide(description: "Contact identifier for reading specific contact")
    var contactId: String?
    
    /// Given name for creating new contact
    @Guide(description: "Given name for creating new contact")
    var givenName: String?
    
    /// Family name for creating new contact
    @Guide(description: "Family name for creating new contact")
    var familyName: String?
    
    /// Email address for creating new contact
    @Guide(description: "Email address for creating new contact")
    var email: String?
    
    /// Phone number for creating new contact
    @Guide(description: "Phone number for creating new contact")
    var phoneNumber: String?
    
    /// Organization name for creating new contact
    @Guide(description: "Organization name for creating new contact")
    var organization: String?
  }
  
  private let store = CNContactStore()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Request access if needed
    let authorized = await requestAccess()
    guard authorized else {
      return createErrorOutput(error: ContactsError.accessDenied)
    }
    
    switch arguments.action.lowercased() {
    case "search":
      return try searchContacts(query: arguments.query)
    case "read":
      return try readContact(contactId: arguments.contactId)
    case "create":
      return try createContact(arguments: arguments)
    default:
      return createErrorOutput(error: ContactsError.invalidAction)
    }
  }
  
  private func requestAccess() async -> Bool {
    do {
      return try await store.requestAccess(for: .contacts)
    } catch {
      return false
    }
  }
  
  private func searchContacts(query: String?) throws -> ToolOutput {
    guard let searchQuery = query, !searchQuery.isEmpty else {
      return createErrorOutput(error: ContactsError.missingQuery)
    }
    
    let keysToFetch: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactEmailAddressesKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactOrganizationNameKey as CNKeyDescriptor,
      CNContactIdentifierKey as CNKeyDescriptor
    ]
    
    let predicate = CNContact.predicateForContacts(matchingName: searchQuery)
    
    do {
      let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
      
      if contacts.isEmpty {
        // Try searching by email or phone
        let allContacts = try store.unifiedContacts(
          matching: NSPredicate(value: true),
          keysToFetch: keysToFetch
        )
        
        let filteredContacts = allContacts.filter { contact in
          // Check emails
          for email in contact.emailAddresses {
            if email.value.contains(searchQuery) {
              return true
            }
          }
          // Check phone numbers
          for phone in contact.phoneNumbers {
            if phone.value.stringValue.contains(searchQuery) {
              return true
            }
          }
          return false
        }
        
        return formatContactsOutput(contacts: filteredContacts, query: searchQuery)
      }
      
      return formatContactsOutput(contacts: contacts, query: searchQuery)
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func readContact(contactId: String?) throws -> ToolOutput {
    guard let id = contactId else {
      return createErrorOutput(error: ContactsError.missingContactId)
    }
    
    let keysToFetch: [CNKeyDescriptor] = [
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactEmailAddressesKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactOrganizationNameKey as CNKeyDescriptor,
      CNContactPostalAddressesKey as CNKeyDescriptor,
      CNContactBirthdayKey as CNKeyDescriptor,
      CNContactNoteKey as CNKeyDescriptor
    ]
    
    do {
      let contact = try store.unifiedContact(withIdentifier: id, keysToFetch: keysToFetch)
      
      var addresses: [String] = []
      for address in contact.postalAddresses {
        let value = address.value
        let formatted = "\(value.street), \(value.city), \(value.state) \(value.postalCode)"
        addresses.append(formatted)
      }
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "contactId": contact.identifier,
          "givenName": contact.givenName,
          "familyName": contact.familyName,
          "fullName": "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
          "organization": contact.organizationName,
          "emails": contact.emailAddresses.map { $0.value as String },
          "phoneNumbers": contact.phoneNumbers.map { $0.value.stringValue },
          "addresses": addresses,
          "birthday": contact.birthday?.date?.description ?? "",
          "note": contact.note
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func createContact(arguments: Arguments) throws -> ToolOutput {
    guard let givenName = arguments.givenName, !givenName.isEmpty else {
      return createErrorOutput(error: ContactsError.missingName)
    }
    
    let newContact = CNMutableContact()
    newContact.givenName = givenName
    
    if let familyName = arguments.familyName {
      newContact.familyName = familyName
    }
    
    if let email = arguments.email {
      newContact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: NSString(string: email))]
    }
    
    if let phone = arguments.phoneNumber {
      newContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))]
    }
    
    if let org = arguments.organization {
      newContact.organizationName = org
    }
    
    let saveRequest = CNSaveRequest()
    saveRequest.add(newContact, toContainerWithIdentifier: nil)
    
    do {
      try store.execute(saveRequest)
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "message": "Contact created successfully",
          "contactId": newContact.identifier,
          "givenName": newContact.givenName,
          "familyName": newContact.familyName,
          "fullName": "\(newContact.givenName) \(newContact.familyName)".trimmingCharacters(in: .whitespaces),
          "email": arguments.email ?? "",
          "phoneNumber": arguments.phoneNumber ?? "",
          "organization": arguments.organization ?? ""
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func formatContactsOutput(contacts: [CNContact], query: String) -> ToolOutput {
    var contactsDescription = ""
    
    for (index, contact) in contacts.enumerated() {
      let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
      let email = contact.emailAddresses.first?.value as String? ?? "No email"
      let phone = contact.phoneNumbers.first?.value.stringValue ?? "No phone"
      let org = contact.organizationName.isEmpty ? "" : " (\(contact.organizationName))"
      
      contactsDescription += "\(index + 1). \(name)\(org) - Email: \(email), Phone: \(phone)\n"
    }
    
    if contactsDescription.isEmpty {
      contactsDescription = "No contacts found matching '\(query)'"
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "query": query,
        "count": contacts.count,
        "results": contactsDescription.trimmingCharacters(in: .whitespacesAndNewlines),
        "message": "Found \(contacts.count) contact(s) matching '\(query)'"
      ])
    )
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform contact operation"
      ])
    )
  }
}

enum ContactsError: Error, LocalizedError {
  case accessDenied
  case invalidAction
  case missingQuery
  case missingContactId
  case missingName
  
  var errorDescription: String? {
    switch self {
    case .accessDenied:
      return "Access to contacts denied. Please grant permission in Settings."
    case .invalidAction:
      return "Invalid action. Use 'search', 'read', or 'create'."
    case .missingQuery:
      return "Search query is required."
    case .missingContactId:
      return "Contact ID is required."
    case .missingName:
      return "Given name is required to create a contact."
    }
  }
}