export const idlFactory = ({ IDL }) => {
  const ContestId = IDL.Text;
  const Judge = IDL.Principal;
  const Time = IDL.Int;
  const PlayTokenAmount = IDL.Nat;
  const Contest = IDL.Record({
    'judges' : IDL.Vec(Judge),
    'decision_time' : Time,
    'contest_id' : ContestId,
    'default_receiver' : IDL.Principal,
    'description' : IDL.Text,
    'stake' : PlayTokenAmount,
  });
  const Decision = IDL.Opt(IDL.Principal);
  const Ballot = IDL.Record({ 'decision' : Decision, 'voter' : Judge });
  const Submission = IDL.Text;
  const ContestResults = IDL.Record({
    'contest' : Contest,
    'ballots' : IDL.Vec(IDL.Tuple(Judge, Ballot)),
    'submissions' : IDL.Vec(IDL.Tuple(IDL.Principal, Submission)),
    'winners' : IDL.Vec(IDL.Principal),
  });
  const JudgeIntrinsicInfo = IDL.Record({
    'description' : IDL.Text,
    'friendly_name' : IDL.Text,
  });
  const JudgeReputation = IDL.Int;
  const ContestStatus = IDL.Record({
    'contest' : Contest,
    'ballots' : IDL.Vec(IDL.Tuple(Judge, Ballot)),
    'submissions' : IDL.Vec(IDL.Tuple(IDL.Principal, Submission)),
    'is_resolved' : IDL.Bool,
  });
  return IDL.Service({
    'check_and_maybe_resolve' : IDL.Func(
        [ContestId],
        [IDL.Opt(ContestResults)],
        [],
      ),
    'downvote_judge_reputation' : IDL.Func([Judge], [IDL.Bool, IDL.Text], []),
    'faucet' : IDL.Func([], [IDL.Bool, IDL.Text], []),
    'list_balances' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Principal, PlayTokenAmount))],
        ['query'],
      ),
    'list_judges' : IDL.Func(
        [],
        [
          IDL.Vec(
            IDL.Tuple(Judge, IDL.Tuple(JudgeIntrinsicInfo, JudgeReputation))
          ),
        ],
        ['query'],
      ),
    'lookup' : IDL.Func([ContestId], [IDL.Opt(ContestStatus)], ['query']),
    'make_contest' : IDL.Func([Contest], [IDL.Bool, IDL.Text], []),
    'register_as_judge' : IDL.Func([JudgeIntrinsicInfo], [], []),
    'send' : IDL.Func(
        [IDL.Principal, PlayTokenAmount],
        [IDL.Bool, IDL.Text],
        [],
      ),
    'submit' : IDL.Func([ContestId, IDL.Text], [IDL.Bool, IDL.Text], []),
    'upvote_judge_reputation' : IDL.Func([Judge], [IDL.Bool, IDL.Text], []),
    'vote' : IDL.Func([ContestId, Decision], [], []),
  });
};
export const init = ({ IDL }) => { return []; };
