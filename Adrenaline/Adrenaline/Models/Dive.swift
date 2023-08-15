// swiftlint:disable all
import Amplify
import Foundation

public struct Dive: Model {
  public let id: String
  public var event: NewEvent
  public var athlete: NewAthlete
  public var number: String
  public var name: String
  public var height: Double
  public var netScore: Double
  public var dd: Double
  public var totalScore: Double
  public var scores: List<JudgeScore>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      event: NewEvent,
      athlete: NewAthlete,
      number: String,
      name: String,
      height: Double,
      netScore: Double,
      dd: Double,
      totalScore: Double,
      scores: List<JudgeScore> = []) {
    self.init(id: id,
      event: event,
      athlete: athlete,
      number: number,
      name: name,
      height: height,
      netScore: netScore,
      dd: dd,
      totalScore: totalScore,
      scores: scores,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      event: NewEvent,
      athlete: NewAthlete,
      number: String,
      name: String,
      height: Double,
      netScore: Double,
      dd: Double,
      totalScore: Double,
      scores: List<JudgeScore> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.event = event
      self.athlete = athlete
      self.number = number
      self.name = name
      self.height = height
      self.netScore = netScore
      self.dd = dd
      self.totalScore = totalScore
      self.scores = scores
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}