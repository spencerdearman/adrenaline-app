// @ts-check
import { initSchema } from '@aws-amplify/datastore'

import { schema } from './schema'

const {
  UserSavedPost,
  Post,
  NewImage,
  MessageNewUser,
  NewUser,
  NewAthlete,
  Video,
  CoachUser,
  NewTeam,
  College,
  NewMeet,
  NewEvent,
  Dive,
  JudgeScore,
  Message,
  DiveMeetsDiver
} = initSchema(schema)

export {
  CoachUser,
  College,
  Dive,
  DiveMeetsDiver,
  JudgeScore,
  Message,
  MessageNewUser,
  NewAthlete,
  NewEvent,
  NewImage,
  NewMeet,
  NewTeam,
  NewUser,
  Post,
  UserSavedPost,
  Video
}
