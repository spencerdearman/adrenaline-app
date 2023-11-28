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
  public var _ttl: Int
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
      totalRating: Double? = nil,
      _ttl: Int) {
    self.init(id: id,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      finaAge: finaAge,
      hsGradYear: hsGradYear,
      springboardRating: springboardRating,
      platformRating: platformRating,
      totalRating: totalRating,
      _ttl: _ttl,
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
      _ttl: Int,
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
      self._ttl = _ttl
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

// Convenience init to add two-week expiration to DiveMeetsDiver object
extension DiveMeetsDiver {
    public init(id: String = UUID().uuidString,
                firstName: String,
                lastName: String,
                gender: String,
                finaAge: Int? = nil,
                hsGradYear: Int? = nil,
                springboardRating: Double? = nil,
                platformRating: Double? = nil,
                totalRating: Double? = nil) {
        let twoWeeksAhead = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date()
        let unixTimestamp = Int(twoWeeksAhead.timeIntervalSince1970)
        self.init(id: id,
                  firstName: firstName,
                  lastName: lastName,
                  gender: gender,
                  finaAge: finaAge,
                  hsGradYear: hsGradYear,
                  springboardRating: springboardRating,
                  platformRating: platformRating,
                  totalRating: totalRating,
                  _ttl: unixTimestamp,
                  createdAt: nil,
                  updatedAt: nil)
    }
}
