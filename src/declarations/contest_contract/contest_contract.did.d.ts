import type { Principal } from '@dfinity/principal';
export interface Ballot { 'decision' : Decision, 'voter' : Judge }
export interface Contest {
  'judges' : Array<Judge>,
  'decision_time' : Time,
  'contest_id' : ContestId,
  'default_receiver' : Principal,
  'description' : string,
  'stake' : PlayTokenAmount,
}
export type ContestId = string;
export interface ContestResults {
  'contest' : Contest,
  'ballots' : Array<[Judge, Ballot]>,
  'submissions' : Array<[Principal, Submission]>,
  'winners' : Array<Principal>,
}
export interface ContestStatus {
  'contest' : Contest,
  'ballots' : Array<[Judge, Ballot]>,
  'submissions' : Array<[Principal, Submission]>,
  'is_resolved' : boolean,
}
export type Decision = [] | [Principal];
export type Judge = Principal;
export interface JudgeIntrinsicInfo {
  'description' : string,
  'friendly_name' : string,
}
export type JudgeReputation = bigint;
export type PlayTokenAmount = bigint;
export type Submission = string;
export type Time = bigint;
export interface _SERVICE {
  'check_and_maybe_resolve' : (arg_0: ContestId) => Promise<
      [] | [ContestResults]
    >,
  'downvote_judge_reputation' : (arg_0: Judge) => Promise<[boolean, string]>,
  'faucet' : () => Promise<[boolean, string]>,
  'list_balances' : () => Promise<Array<[Principal, PlayTokenAmount]>>,
  'list_judges' : () => Promise<
      Array<[Judge, [JudgeIntrinsicInfo, JudgeReputation]]>
    >,
  'lookup' : (arg_0: ContestId) => Promise<[] | [ContestStatus]>,
  'make_contest' : (arg_0: Contest) => Promise<[boolean, string]>,
  'register_as_judge' : (arg_0: JudgeIntrinsicInfo) => Promise<undefined>,
  'send' : (arg_0: Principal, arg_1: PlayTokenAmount) => Promise<
      [boolean, string]
    >,
  'submit' : (arg_0: ContestId, arg_1: string) => Promise<[boolean, string]>,
  'upvote_judge_reputation' : (arg_0: Judge) => Promise<[boolean, string]>,
  'vote' : (arg_0: ContestId, arg_1: Decision) => Promise<undefined>,
}
