import { ModelInit, MutableModel, __modelMeta__, ManagedIdentifier } from "@aws-amplify/datastore";
// @ts-ignore
import { LazyLoading, LazyLoadingDisabled, AsyncCollection, AsyncItem } from "@aws-amplify/datastore";





type EagerUserSavedPost = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<UserSavedPost, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly newuserID: string;
  readonly postID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyUserSavedPost = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<UserSavedPost, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly newuserID: string;
  readonly postID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type UserSavedPost = LazyLoading extends LazyLoadingDisabled ? EagerUserSavedPost : LazyUserSavedPost

export declare const UserSavedPost: (new (init: ModelInit<UserSavedPost>) => UserSavedPost) & {
  copyOf(source: UserSavedPost, mutator: (draft: MutableModel<UserSavedPost>) => MutableModel<UserSavedPost> | void): UserSavedPost;
}

type EagerPost = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Post, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly caption?: string | null;
  readonly creationDate: string;
  readonly images?: (NewImage | null)[] | null;
  readonly videos?: (Video | null)[] | null;
  readonly newuserID: string;
  readonly usersSaving?: (UserSavedPost | null)[] | null;
  readonly isCoachesOnly: boolean;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyPost = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Post, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly caption?: string | null;
  readonly creationDate: string;
  readonly images: AsyncCollection<NewImage>;
  readonly videos: AsyncCollection<Video>;
  readonly newuserID: string;
  readonly usersSaving: AsyncCollection<UserSavedPost>;
  readonly isCoachesOnly: boolean;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type Post = LazyLoading extends LazyLoadingDisabled ? EagerPost : LazyPost

export declare const Post: (new (init: ModelInit<Post>) => Post) & {
  copyOf(source: Post, mutator: (draft: MutableModel<Post>) => MutableModel<Post> | void): Post;
}

type EagerNewImage = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewImage, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly s3key: string;
  readonly uploadDate: string;
  readonly postID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyNewImage = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewImage, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly s3key: string;
  readonly uploadDate: string;
  readonly postID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type NewImage = LazyLoading extends LazyLoadingDisabled ? EagerNewImage : LazyNewImage

export declare const NewImage: (new (init: ModelInit<NewImage>) => NewImage) & {
  copyOf(source: NewImage, mutator: (draft: MutableModel<NewImage>) => MutableModel<NewImage> | void): NewImage;
}

type EagerMessageNewUser = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<MessageNewUser, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly isSender: boolean;
  readonly newuserID: string;
  readonly messageID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyMessageNewUser = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<MessageNewUser, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly isSender: boolean;
  readonly newuserID: string;
  readonly messageID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type MessageNewUser = LazyLoading extends LazyLoadingDisabled ? EagerMessageNewUser : LazyMessageNewUser

export declare const MessageNewUser: (new (init: ModelInit<MessageNewUser>) => MessageNewUser) & {
  copyOf(source: MessageNewUser, mutator: (draft: MutableModel<MessageNewUser>) => MutableModel<MessageNewUser> | void): MessageNewUser;
}

type EagerNewUser = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewUser, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly email: string;
  readonly phone?: string | null;
  readonly diveMeetsID?: string | null;
  readonly accountType: string;
  readonly athlete?: NewAthlete | null;
  readonly coach?: CoachUser | null;
  readonly posts?: (Post | null)[] | null;
  readonly tokens: string[];
  readonly savedPosts?: (UserSavedPost | null)[] | null;
  readonly favoritesIds: string[];
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newUserAthleteId?: string | null;
  readonly newUserCoachId?: string | null;
}

type LazyNewUser = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewUser, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly email: string;
  readonly phone?: string | null;
  readonly diveMeetsID?: string | null;
  readonly accountType: string;
  readonly athlete: AsyncItem<NewAthlete | undefined>;
  readonly coach: AsyncItem<CoachUser | undefined>;
  readonly posts: AsyncCollection<Post>;
  readonly tokens: string[];
  readonly savedPosts: AsyncCollection<UserSavedPost>;
  readonly favoritesIds: string[];
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newUserAthleteId?: string | null;
  readonly newUserCoachId?: string | null;
}

export declare type NewUser = LazyLoading extends LazyLoadingDisabled ? EagerNewUser : LazyNewUser

export declare const NewUser: (new (init: ModelInit<NewUser>) => NewUser) & {
  copyOf(source: NewUser, mutator: (draft: MutableModel<NewUser>) => MutableModel<NewUser> | void): NewUser;
}

type EagerNewAthlete = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewAthlete, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly user: NewUser;
  readonly team?: NewTeam | null;
  readonly college?: College | null;
  readonly academics?: AcademicRecord | null;
  readonly heightFeet: number;
  readonly heightInches: number;
  readonly weight: number;
  readonly weightUnit: string;
  readonly gender: string;
  readonly age: number;
  readonly dateOfBirth: string;
  readonly graduationYear: number;
  readonly highSchool: string;
  readonly hometown: string;
  readonly springboardRating?: number | null;
  readonly platformRating?: number | null;
  readonly totalRating?: number | null;
  readonly dives?: Dive[] | null;
  readonly collegeID?: string | null;
  readonly newteamID?: string | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newAthleteUserId: string;
  readonly newAthleteAcademicsId?: string | null;
}

type LazyNewAthlete = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewAthlete, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly user: AsyncItem<NewUser>;
  readonly team: AsyncItem<NewTeam | undefined>;
  readonly college: AsyncItem<College | undefined>;
  readonly academics: AsyncItem<AcademicRecord | undefined>;
  readonly heightFeet: number;
  readonly heightInches: number;
  readonly weight: number;
  readonly weightUnit: string;
  readonly gender: string;
  readonly age: number;
  readonly dateOfBirth: string;
  readonly graduationYear: number;
  readonly highSchool: string;
  readonly hometown: string;
  readonly springboardRating?: number | null;
  readonly platformRating?: number | null;
  readonly totalRating?: number | null;
  readonly dives: AsyncCollection<Dive>;
  readonly collegeID?: string | null;
  readonly newteamID?: string | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newAthleteUserId: string;
  readonly newAthleteAcademicsId?: string | null;
}

export declare type NewAthlete = LazyLoading extends LazyLoadingDisabled ? EagerNewAthlete : LazyNewAthlete

export declare const NewAthlete: (new (init: ModelInit<NewAthlete>) => NewAthlete) & {
  copyOf(source: NewAthlete, mutator: (draft: MutableModel<NewAthlete>) => MutableModel<NewAthlete> | void): NewAthlete;
}

type EagerVideo = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Video, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly s3key: string;
  readonly uploadDate: string;
  readonly postID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyVideo = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Video, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly s3key: string;
  readonly uploadDate: string;
  readonly postID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type Video = LazyLoading extends LazyLoadingDisabled ? EagerVideo : LazyVideo

export declare const Video: (new (init: ModelInit<Video>) => Video) & {
  copyOf(source: Video, mutator: (draft: MutableModel<Video>) => MutableModel<Video> | void): Video;
}

type EagerCoachUser = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<CoachUser, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly user?: NewUser | null;
  readonly team?: NewTeam | null;
  readonly college?: College | null;
  readonly favoritesOrder: number[];
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly coachUserUserId?: string | null;
  readonly coachUserTeamId?: string | null;
  readonly coachUserCollegeId?: string | null;
}

type LazyCoachUser = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<CoachUser, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly user: AsyncItem<NewUser | undefined>;
  readonly team: AsyncItem<NewTeam | undefined>;
  readonly college: AsyncItem<College | undefined>;
  readonly favoritesOrder: number[];
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly coachUserUserId?: string | null;
  readonly coachUserTeamId?: string | null;
  readonly coachUserCollegeId?: string | null;
}

export declare type CoachUser = LazyLoading extends LazyLoadingDisabled ? EagerCoachUser : LazyCoachUser

export declare const CoachUser: (new (init: ModelInit<CoachUser>) => CoachUser) & {
  copyOf(source: CoachUser, mutator: (draft: MutableModel<CoachUser>) => MutableModel<CoachUser> | void): CoachUser;
}

type EagerNewTeam = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewTeam, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly name: string;
  readonly coach?: CoachUser | null;
  readonly athletes: NewAthlete[];
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newTeamCoachId?: string | null;
}

type LazyNewTeam = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewTeam, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly name: string;
  readonly coach: AsyncItem<CoachUser | undefined>;
  readonly athletes: AsyncCollection<NewAthlete>;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newTeamCoachId?: string | null;
}

export declare type NewTeam = LazyLoading extends LazyLoadingDisabled ? EagerNewTeam : LazyNewTeam

export declare const NewTeam: (new (init: ModelInit<NewTeam>) => NewTeam) & {
  copyOf(source: NewTeam, mutator: (draft: MutableModel<NewTeam>) => MutableModel<NewTeam> | void): NewTeam;
}

type EagerCollege = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<College, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly name: string;
  readonly imageLink: string;
  readonly athletes: NewAthlete[];
  readonly coach?: CoachUser | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly collegeCoachId?: string | null;
}

type LazyCollege = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<College, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly name: string;
  readonly imageLink: string;
  readonly athletes: AsyncCollection<NewAthlete>;
  readonly coach: AsyncItem<CoachUser | undefined>;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly collegeCoachId?: string | null;
}

export declare type College = LazyLoading extends LazyLoadingDisabled ? EagerCollege : LazyCollege

export declare const College: (new (init: ModelInit<College>) => College) & {
  copyOf(source: College, mutator: (draft: MutableModel<College>) => MutableModel<College> | void): College;
}

type EagerNewMeet = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewMeet, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly meetID: number;
  readonly name: string;
  readonly organization?: string | null;
  readonly startDate: string;
  readonly endDate: string;
  readonly city: string;
  readonly state: string;
  readonly country: string;
  readonly link: string;
  readonly meetType: number;
  readonly events: NewEvent[];
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyNewMeet = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewMeet, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly meetID: number;
  readonly name: string;
  readonly organization?: string | null;
  readonly startDate: string;
  readonly endDate: string;
  readonly city: string;
  readonly state: string;
  readonly country: string;
  readonly link: string;
  readonly meetType: number;
  readonly events: AsyncCollection<NewEvent>;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type NewMeet = LazyLoading extends LazyLoadingDisabled ? EagerNewMeet : LazyNewMeet

export declare const NewMeet: (new (init: ModelInit<NewMeet>) => NewMeet) & {
  copyOf(source: NewMeet, mutator: (draft: MutableModel<NewMeet>) => MutableModel<NewMeet> | void): NewMeet;
}

type EagerNewEvent = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewEvent, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly meet: NewMeet;
  readonly name: string;
  readonly date: string;
  readonly link: string;
  readonly numEntries: number;
  readonly dives: Dive[];
  readonly newmeetID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newMeetEventsId: string;
}

type LazyNewEvent = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<NewEvent, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly meet: AsyncItem<NewMeet>;
  readonly name: string;
  readonly date: string;
  readonly link: string;
  readonly numEntries: number;
  readonly dives: AsyncCollection<Dive>;
  readonly newmeetID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newMeetEventsId: string;
}

export declare type NewEvent = LazyLoading extends LazyLoadingDisabled ? EagerNewEvent : LazyNewEvent

export declare const NewEvent: (new (init: ModelInit<NewEvent>) => NewEvent) & {
  copyOf(source: NewEvent, mutator: (draft: MutableModel<NewEvent>) => MutableModel<NewEvent> | void): NewEvent;
}

type EagerDive = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Dive, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly event: NewEvent;
  readonly athlete: NewAthlete;
  readonly number: string;
  readonly name: string;
  readonly height: number;
  readonly netScore: number;
  readonly dd: number;
  readonly totalScore: number;
  readonly scores: JudgeScore[];
  readonly newathleteID: string;
  readonly neweventID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newEventDivesId: string;
  readonly newAthleteDivesId: string;
}

type LazyDive = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Dive, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly event: AsyncItem<NewEvent>;
  readonly athlete: AsyncItem<NewAthlete>;
  readonly number: string;
  readonly name: string;
  readonly height: number;
  readonly netScore: number;
  readonly dd: number;
  readonly totalScore: number;
  readonly scores: AsyncCollection<JudgeScore>;
  readonly newathleteID: string;
  readonly neweventID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly newEventDivesId: string;
  readonly newAthleteDivesId: string;
}

export declare type Dive = LazyLoading extends LazyLoadingDisabled ? EagerDive : LazyDive

export declare const Dive: (new (init: ModelInit<Dive>) => Dive) & {
  copyOf(source: Dive, mutator: (draft: MutableModel<Dive>) => MutableModel<Dive> | void): Dive;
}

type EagerJudgeScore = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<JudgeScore, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly dive: Dive;
  readonly score: number;
  readonly diveID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly diveScoresId: string;
}

type LazyJudgeScore = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<JudgeScore, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly dive: AsyncItem<Dive>;
  readonly score: number;
  readonly diveID: string;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly diveScoresId: string;
}

export declare type JudgeScore = LazyLoading extends LazyLoadingDisabled ? EagerJudgeScore : LazyJudgeScore

export declare const JudgeScore: (new (init: ModelInit<JudgeScore>) => JudgeScore) & {
  copyOf(source: JudgeScore, mutator: (draft: MutableModel<JudgeScore>) => MutableModel<JudgeScore> | void): JudgeScore;
}

type EagerMessage = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Message, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly body: string;
  readonly creationDate: string;
  readonly MessageNewUsers?: (MessageNewUser | null)[] | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyMessage = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<Message, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly body: string;
  readonly creationDate: string;
  readonly MessageNewUsers: AsyncCollection<MessageNewUser>;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type Message = LazyLoading extends LazyLoadingDisabled ? EagerMessage : LazyMessage

export declare const Message: (new (init: ModelInit<Message>) => Message) & {
  copyOf(source: Message, mutator: (draft: MutableModel<Message>) => MutableModel<Message> | void): Message;
}

type EagerDiveMeetsDiver = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<DiveMeetsDiver, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly gender: string;
  readonly finaAge?: number | null;
  readonly hsGradYear?: number | null;
  readonly springboardRating?: number | null;
  readonly platformRating?: number | null;
  readonly totalRating?: number | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

type LazyDiveMeetsDiver = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<DiveMeetsDiver, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly gender: string;
  readonly finaAge?: number | null;
  readonly hsGradYear?: number | null;
  readonly springboardRating?: number | null;
  readonly platformRating?: number | null;
  readonly totalRating?: number | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
}

export declare type DiveMeetsDiver = LazyLoading extends LazyLoadingDisabled ? EagerDiveMeetsDiver : LazyDiveMeetsDiver

export declare const DiveMeetsDiver: (new (init: ModelInit<DiveMeetsDiver>) => DiveMeetsDiver) & {
  copyOf(source: DiveMeetsDiver, mutator: (draft: MutableModel<DiveMeetsDiver>) => MutableModel<DiveMeetsDiver> | void): DiveMeetsDiver;
}

type EagerAcademicRecord = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<AcademicRecord, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly athlete: NewAthlete;
  readonly satScore?: number | null;
  readonly actScore?: number | null;
  readonly weightedGPA?: number | null;
  readonly gpaScale?: number | null;
  readonly coursework?: string | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly academicRecordAthleteId: string;
}

type LazyAcademicRecord = {
  readonly [__modelMeta__]: {
    identifier: ManagedIdentifier<AcademicRecord, 'id'>;
    readOnlyFields: 'createdAt' | 'updatedAt';
  };
  readonly id: string;
  readonly athlete: AsyncItem<NewAthlete>;
  readonly satScore?: number | null;
  readonly actScore?: number | null;
  readonly weightedGPA?: number | null;
  readonly gpaScale?: number | null;
  readonly coursework?: string | null;
  readonly createdAt?: string | null;
  readonly updatedAt?: string | null;
  readonly academicRecordAthleteId: string;
}

export declare type AcademicRecord = LazyLoading extends LazyLoadingDisabled ? EagerAcademicRecord : LazyAcademicRecord

export declare const AcademicRecord: (new (init: ModelInit<AcademicRecord>) => AcademicRecord) & {
  copyOf(source: AcademicRecord, mutator: (draft: MutableModel<AcademicRecord>) => MutableModel<AcademicRecord> | void): AcademicRecord;
}