import type { Principal } from '@dfinity/principal';
export interface Ballot { 'decision' : Decision, 'voter' : Judge }
export interface Contest {
  'judges' : Array<Judge>,
  'decision_time' : Time,
  'contest_id' : ContestId,
  'default_receiver' : Principal,
  'description' : string,
  'submissions' : Array<[Principal, string]>,
  'stake' : PlayTokenAmount,
}
export type ContestId = string;
export interface ContestResults {
  'contest' : Contest,
  'ballots' : Array<[Judge, Ballot]>,
  'winners' : Array<Principal>,
}
export interface ContestStatus {
  'contest' : Contest,
  'ballots' : Array<[Judge, Ballot]>,
}
export type Decision = [] | [Principal];
export type Judge = Principal;
export type PlayTokenAmount = bigint;
export type Time = bigint;
export interface _SERVICE {
  'check_and_maybe_resolve' : (arg_0: ContestId) => Promise<
      [] | [ContestResults]
    >,
  'check_balances' : () => Promise<Array<[Principal, PlayTokenAmount]>>,
  'faucet' : (arg_0: ContestId, arg_1: Decision) => Promise<undefined>,
  'lookup' : (arg_0: ContestId) => Promise<[] | [ContestStatus]>,
  'make_contest' : (arg_0: Contest) => Promise<[boolean, string]>,
  'vote' : (arg_0: ContestId, arg_1: Decision) => Promise<undefined>,
}
