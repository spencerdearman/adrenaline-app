// swiftlint:disable all
import Amplify
import Foundation

public struct NewEvent: Model {
  public let id: String
  public var meet: NewMeet
  public var name: String
  public var date: Temporal.Date
  public var link: String
  public var numEntries: Int
  public var dives: List<Dive>?
  public var newmeetID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      meet: NewMeet,
      name: String,
      date: Temporal.Date,
      link: String,
      numEntries: Int,
      dives: List<Dive> = [],
      newmeetID: String) {
    self.init(id: id,
      meet: meet,
      name: name,
      date: date,
      link: link,
      numEntries: numEntries,
      dives: dives,
      newmeetID: newmeetID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      meet: NewMeet,
      name: String,
      date: Temporal.Date,
      link: String,
      numEntries: Int,
      dives: List<Dive> = [],
      newmeetID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.meet = meet
      self.name = name
      self.date = date
      self.link = link
      self.numEntries = numEntries
      self.dives = dives
      self.newmeetID = newmeetID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}