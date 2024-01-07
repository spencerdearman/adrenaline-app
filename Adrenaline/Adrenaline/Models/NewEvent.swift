// swiftlint:disable all
import Amplify
import Foundation

public struct NewEvent: Model {
  public let id: String
  internal var _meet: LazyReference<NewMeet>
  public var meet: NewMeet   {
      get async throws { 
        try await _meet.require()
      } 
    }
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
      self._meet = LazyReference(meet)
      self.name = name
      self.date = date
      self.link = link
      self.numEntries = numEntries
      self.dives = dives
      self.newmeetID = newmeetID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setMeet(_ meet: NewMeet) {
    self._meet = LazyReference(meet)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _meet = try values.decodeIfPresent(LazyReference<NewMeet>.self, forKey: .meet) ?? LazyReference(identifiers: nil)
      name = try values.decode(String.self, forKey: .name)
      date = try values.decode(Temporal.Date.self, forKey: .date)
      link = try values.decode(String.self, forKey: .link)
      numEntries = try values.decode(Int.self, forKey: .numEntries)
      dives = try values.decodeIfPresent(List<Dive>?.self, forKey: .dives) ?? .init()
      newmeetID = try values.decode(String.self, forKey: .newmeetID)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_meet, forKey: .meet)
      try container.encode(name, forKey: .name)
      try container.encode(date, forKey: .date)
      try container.encode(link, forKey: .link)
      try container.encode(numEntries, forKey: .numEntries)
      try container.encode(dives, forKey: .dives)
      try container.encode(newmeetID, forKey: .newmeetID)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}