// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "6f2a52fa64b39c34961da5d6f830a704"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: MessageNewUser.self)
    ModelRegistry.register(modelType: NewUser.self)
    ModelRegistry.register(modelType: NewAthlete.self)
    ModelRegistry.register(modelType: Video.self)
    ModelRegistry.register(modelType: CoachUser.self)
    ModelRegistry.register(modelType: NewFollowed.self)
    ModelRegistry.register(modelType: NewTeam.self)
    ModelRegistry.register(modelType: College.self)
    ModelRegistry.register(modelType: NewMeet.self)
    ModelRegistry.register(modelType: NewEvent.self)
    ModelRegistry.register(modelType: Dive.self)
    ModelRegistry.register(modelType: JudgeScore.self)
    ModelRegistry.register(modelType: Message.self)
    ModelRegistry.register(modelType: NewUserNewFollowed.self)
  }
}