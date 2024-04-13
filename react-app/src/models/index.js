// @ts-check
import { initSchema } from '@aws-amplify/datastore';
import { schema } from './schema';

const TeamJoinRequestStatus = {
  "REQUESTED_BY_ATHLETE": "REQUESTED_BY_ATHLETE",
  "REQUESTED_BY_COACH": "REQUESTED_BY_COACH",
  "APPROVED": "APPROVED",
  "DENIED_BY_ATHLETE": "DENIED_BY_ATHLETE",
  "DENIED_BY_COACH_FIRST": "DENIED_BY_COACH_FIRST",
  "DENIED_BY_COACH_SECOND": "DENIED_BY_COACH_SECOND",
  "DENIED_BY_COACH_THIRD": "DENIED_BY_COACH_THIRD"
};

const { UserSavedPost, Post, NewImage, MessageNewUser, NewUser, NewAthlete, Video, CoachUser, NewTeam, College, NewMeet, NewEvent, Dive, JudgeScore, Message, DiveMeetsDiver, AcademicRecord, TeamJoinRequest } = initSchema(schema);

export {
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
  DiveMeetsDiver,
  AcademicRecord,
  TeamJoinRequest,
  TeamJoinRequestStatus
};