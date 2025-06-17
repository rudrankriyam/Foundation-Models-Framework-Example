//
//  ContactsTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Contacts
import Foundation
import FoundationModels

/// `ContactsTool` provides access to the Contacts framework for managing contact information.
///
/// This tool can search, create, read, and update contacts from the user's address book.
/// It requires appropriate permissions to access contact data.
struct ContactsTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "manageContacts"
  /// A brief description of the tool's functionality.
  let description = "Search, create, read, or update contacts from the address book"
  
  /// Arguments for contact operations.
  @Generable
  struct Arguments {
    /// The action to perform: "search", "create", "read", "update"
    @Guide(description: "The action to perform: 'search', 'create', 'read', 'update'")
    var action: String
    
    /// Search query (for search action)
    @Guide(description: "Search query (for search action)")
    var searchQuery: String?
    
    /// Contact identifier (for read/update actions)
    @Guide(description: "Contact identifier (for read/update actions)")
    var contactId: String?
    
    /// Given name (first name)
    @Guide(description: "Given name (first name)")
    var givenName: String?
    
    /// Family name (last name)
    @Guide(description: "Family name (last name)")
    var familyName: String?
    
    /// Organization/company name
    @Guide(description: "Organization/company name")
    var organization: String?
    
    /// Job title
    @Guide(description: "Job title")
    var jobTitle: String?
    
    /// Phone numbers as comma-separated list
    @Guide(description: "Phone numbers as comma-separated list")
    var phoneNumbers: String?
    
    /// Email addresses as comma-separated list
    @Guide(description: "Email addresses as comma-separated list")
    var emailAddresses: String?
    
    /// Birthday in ISO 8601 format
    @Guide(description: "Birthday in ISO 8601 format")
    var birthday: String?
    
    /// Notes about the contact
    @Guide(description: "Notes about the contact")
    var note: String?
  }
  
  /// Contact data structure
  struct ContactData: Encodable {
    let id: String
    let givenName: String
    let familyName: String
    let fullName: String
    let organization: String?
    let jobTitle: String?
    let phoneNumbers: [PhoneData]
    let emailAddresses: [EmailData]
    let birthday: String?
    let note: String?
  }
  
  struct PhoneData: Encodable {
    let label: String
    let number: String
  }
  
  struct EmailData: Encodable {
    let label: String
    let address: String
  }
  
  private let contactStore = CNContactStore()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Request access to contacts
    let granted = try await requestContactsAccess()
    guard granted else {
      return createErrorOutput(error: ContactsError.accessDenied)
    }
    
    switch arguments.action.lowercased() {
    case "search":
      return try await searchContacts(arguments: arguments)
    case "create":
      return try await createContact(arguments: arguments)
    case "read":
      return try await readContact(arguments: arguments)
    case "update":
      return try await updateContact(arguments: arguments)
    default:
      return createErrorOutput(error: ContactsError.invalidAction)
    }
  }
  
  private func requestContactsAccess() async throws -> Bool {
    return try await withCheckedThrowingContinuation { continuation in
      contactStore.requestAccess(for: .contacts) { granted, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: granted)
        }
      }
    }
  }
  
  private func searchContacts(arguments: Arguments) async throws -> ToolOutput {
    guard let query = arguments.searchQuery else {
      return createErrorOutput(error: ContactsError.missingSearchQuery)
    }
    
    let keysToFetch = getKeysToFetch()
    let predicate = CNContact.predicateForContacts(matchingName: query)
    
    let contacts = try contactStore.unifiedContacts(
      matching: predicate,
      keysToFetch: keysToFetch
    )
    
    let contactDataArray = contacts.map { contact in
      mapContactToData(contact)
    }
    
    return createSuccessOutput(
      message: "Found \(contactDataArray.count) contacts",
      contacts: contactDataArray
    )
  }
  
  private func createContact(arguments: Arguments) async throws -> ToolOutput {
    let contact = CNMutableContact()
    
    if let givenName = arguments.givenName {
      contact.givenName = givenName
    }
    
    if let familyName = arguments.familyName {
      contact.familyName = familyName
    }
    
    if let organization = arguments.organization {
      contact.organizationName = organization
    }
    
    if let jobTitle = arguments.jobTitle {
      contact.jobTitle = jobTitle
    }
    
    if let phoneNumbers = arguments.phoneNumbers {
      contact.phoneNumbers = parsePhoneNumbers(phoneNumbers)
    }
    
    if let emailAddresses = arguments.emailAddresses {
      contact.emailAddresses = parseEmailAddresses(emailAddresses)
    }
    
    if let birthdayString = arguments.birthday,
       let birthday = parseBirthday(birthdayString) {
      contact.birthday = birthday
    }
    
    if let note = arguments.note {
      contact.note = note
    }
    
    let saveRequest = CNSaveRequest()
    saveRequest.add(contact, toContainerWithIdentifier: nil)
    
    try contactStore.execute(saveRequest)
    
    let contactData = mapContactToData(contact)
    
    return createSuccessOutput(
      message: "Contact created successfully",
      contacts: [contactData]
    )
  }
  
  private func readContact(arguments: Arguments) async throws -> ToolOutput {
    guard let contactId = arguments.contactId else {
      return createErrorOutput(error: ContactsError.missingContactId)
    }
    
    let keysToFetch = getKeysToFetch()
    
    guard let contact = try? contactStore.unifiedContact(
      withIdentifier: contactId,
      keysToFetch: keysToFetch
    ) else {
      return createErrorOutput(error: ContactsError.contactNotFound)
    }
    
    let contactData = mapContactToData(contact)
    
    return createSuccessOutput(
      message: "Contact retrieved successfully",
      contacts: [contactData]
    )
  }
  
  private func updateContact(arguments: Arguments) async throws -> ToolOutput {
    guard let contactId = arguments.contactId else {
      return createErrorOutput(error: ContactsError.missingContactId)
    }
    
    let keysToFetch = getKeysToFetch()
    
    guard let contact = try? contactStore.unifiedContact(
      withIdentifier: contactId,
      keysToFetch: keysToFetch
    ).mutableCopy() as? CNMutableContact else {
      return createErrorOutput(error: ContactsError.contactNotFound)
    }
    
    if let givenName = arguments.givenName {
      contact.givenName = givenName
    }
    
    if let familyName = arguments.familyName {
      contact.familyName = familyName
    }
    
    if let organization = arguments.organization {
      contact.organizationName = organization
    }
    
    if let jobTitle = arguments.jobTitle {
      contact.jobTitle = jobTitle
    }
    
    if let phoneNumbers = arguments.phoneNumbers {
      contact.phoneNumbers = parsePhoneNumbers(phoneNumbers)
    }
    
    if let emailAddresses = arguments.emailAddresses {
      contact.emailAddresses = parseEmailAddresses(emailAddresses)
    }
    
    if let birthdayString = arguments.birthday,
       let birthday = parseBirthday(birthdayString) {
      contact.birthday = birthday
    }
    
    if let note = arguments.note {
      contact.note = note
    }
    
    let saveRequest = CNSaveRequest()
    saveRequest.update(contact)
    
    try contactStore.execute(saveRequest)
    
    let contactData = mapContactToData(contact)
    
    return createSuccessOutput(
      message: "Contact updated successfully",
      contacts: [contactData]
    )
  }
  
  private func getKeysToFetch() -> [CNKeyDescriptor] {
    return [
      CNContactIdentifierKey,
      CNContactGivenNameKey,
      CNContactFamilyNameKey,
      CNContactOrganizationNameKey,
      CNContactJobTitleKey,
      CNContactPhoneNumbersKey,
      CNContactEmailAddressesKey,
      CNContactBirthdayKey,
      CNContactNoteKey,
      CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
    ] as [CNKeyDescriptor]
  }
  
  private func mapContactToData(_ contact: CNContact) -> ContactData {
    let formatter = CNContactFormatter()
    formatter.style = .fullName
    let fullName = formatter.string(from: contact) ?? "\(contact.givenName) \(contact.familyName)"
    
    let phoneNumbers = contact.phoneNumbers.map { phoneNumber in
      PhoneData(
        label: CNLabeledValue<NSString>.localizedString(forLabel: phoneNumber.label ?? ""),
        number: phoneNumber.value.stringValue
      )
    }
    
    let emailAddresses = contact.emailAddresses.map { email in
      EmailData(
        label: CNLabeledValue<NSString>.localizedString(forLabel: email.label ?? ""),
        address: email.value as String
      )
    }
    
    var birthdayString: String?
    if let birthday = contact.birthday {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withFullDate]
      let calendar = Calendar.current
      if let date = calendar.date(from: birthday) {
        birthdayString = formatter.string(from: date)
      }
    }
    
    return ContactData(
      id: contact.identifier,
      givenName: contact.givenName,
      familyName: contact.familyName,
      fullName: fullName,
      organization: contact.organizationName.isEmpty ? nil : contact.organizationName,
      jobTitle: contact.jobTitle.isEmpty ? nil : contact.jobTitle,
      phoneNumbers: phoneNumbers,
      emailAddresses: emailAddresses,
      birthday: birthdayString,
      note: contact.note.isEmpty ? nil : contact.note
    )
  }
  
  private func parsePhoneNumbers(_ phoneNumbersString: String) -> [CNLabeledValue<CNPhoneNumber>] {
    let numbers = phoneNumbersString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    
    return numbers.enumerated().map { index, number in
      let label = index == 0 ? CNLabelPhoneNumberMain : CNLabelPhoneNumberMobile
      return CNLabeledValue(
        label: label,
        value: CNPhoneNumber(stringValue: number)
      )
    }
  }
  
  private func parseEmailAddresses(_ emailsString: String) -> [CNLabeledValue<NSString>] {
    let emails = emailsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    
    return emails.enumerated().map { index, email in
      let label = index == 0 ? CNLabelHome : CNLabelWork
      return CNLabeledValue(
        label: label,
        value: email as NSString
      )
    }
  }
  
  private func parseBirthday(_ birthdayString: String) -> DateComponents? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    
    guard let date = formatter.date(from: birthdayString) else { return nil }
    
    let calendar = Calendar.current
    return calendar.dateComponents([.year, .month, .day], from: date)
  }
  
  private func createSuccessOutput(message: String, contacts: [ContactData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": contacts.count
    ]
    
    if !contacts.isEmpty {
      properties["contacts"] = contacts.map { contact in
        var contactDict: [String: Any] = [
          "id": contact.id,
          "givenName": contact.givenName,
          "familyName": contact.familyName,
          "fullName": contact.fullName
        ]
        
        if let organization = contact.organization {
          contactDict["organization"] = organization
        }
        
        if let jobTitle = contact.jobTitle {
          contactDict["jobTitle"] = jobTitle
        }
        
        if !contact.phoneNumbers.isEmpty {
          contactDict["phoneNumbers"] = contact.phoneNumbers.map { phone in
            ["label": phone.label, "number": phone.number]
          }
        }
        
        if !contact.emailAddresses.isEmpty {
          contactDict["emailAddresses"] = contact.emailAddresses.map { email in
            ["label": email.label, "address": email.address]
          }
        }
        
        if let birthday = contact.birthday {
          contactDict["birthday"] = birthday
        }
        
        if let note = contact.note {
          contactDict["note"] = note
        }
        
        return contactDict
      }
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
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
  case missingSearchQuery
  case missingContactId
  case contactNotFound
  
  var errorDescription: String? {
    switch self {
    case .accessDenied:
      return "Access to contacts denied. Please grant permission in Settings."
    case .invalidAction:
      return "Invalid action. Use 'search', 'create', 'read', or 'update'."
    case .missingSearchQuery:
      return "Search query is required for search action."
    case .missingContactId:
      return "Contact ID is required for this operation."
    case .contactNotFound:
      return "Contact not found with the provided ID."
    }
  }
}