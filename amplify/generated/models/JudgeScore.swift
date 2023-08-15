// swiftlint:disable all
import Amplify
import Foundation

public struct JudgeScore: Model {
  public let id: String
  public var dive: Dive
  public var score: Double
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      dive: Dive,
      score: Double) {
    self.init(id: id,
      dive: dive,
      score: score,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      dive: Dive,
      score: Double,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.dive = dive
      self.score = score
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}