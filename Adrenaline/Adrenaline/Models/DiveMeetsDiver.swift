// swiftlint:disable all
import Amplify
import Foundation

public struct DiveMeetsDiver: Model {
  public let id: String
  public var firstName: String
  public var lastName: String
  public var gender: String
  public var finaAge: Int?
  public var hsGradYear: Int?
  public var springboardRating: Double?
  public var platformRating: Double?
  public var totalRating: Double?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      gender: String,
      finaAge: Int? = nil,
      hsGradYear: Int? = nil,
      springboardRating: Double? = nil,
      platformRating: Double? = nil,
      totalRating: Double? = nil) {
    self.init(id: id,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      finaAge: finaAge,
      hsGradYear: hsGradYear,
      springboardRating: springboardRating,
      platformRating: platformRating,
      totalRating: totalRating,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      gender: String,
      finaAge: Int? = nil,
      hsGradYear: Int? = nil,
      springboardRating: Double? = nil,
      platformRating: Double? = nil,
      totalRating: Double? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.firstName = firstName
      self.lastName = lastName
      self.gender = gender
      self.finaAge = finaAge
      self.hsGradYear = hsGradYear
      self.springboardRating = springboardRating
      self.platformRating = platformRating
      self.totalRating = totalRating
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}