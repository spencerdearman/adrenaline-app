// swiftlint:disable all
import Amplify
import Foundation

public struct NewMeet: Model {
  public let id: String
  public var meetID: Int
  public var name: String
  public var organization: String?
  public var startDate: Temporal.Date
  public var endDate: Temporal.Date
  public var city: String
  public var state: String
  public var country: String
  public var link: String
  public var meetType: Int
  public var events: List<NewEvent>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      meetID: Int,
      name: String,
      organization: String? = nil,
      startDate: Temporal.Date,
      endDate: Temporal.Date,
      city: String,
      state: String,
      country: String,
      link: String,
      meetType: Int,
      events: List<NewEvent> = []) {
    self.init(id: id,
      meetID: meetID,
      name: name,
      organization: organization,
      startDate: startDate,
      endDate: endDate,
      city: city,
      state: state,
      country: country,
      link: link,
      meetType: meetType,
      events: events,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      meetID: Int,
      name: String,
      organization: String? = nil,
      startDate: Temporal.Date,
      endDate: Temporal.Date,
      city: String,
      state: String,
      country: String,
      link: String,
      meetType: Int,
      events: List<NewEvent> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.meetID = meetID
      self.name = name
      self.organization = organization
      self.startDate = startDate
      self.endDate = endDate
      self.city = city
      self.state = state
      self.country = country
      self.link = link
      self.meetType = meetType
      self.events = events
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}