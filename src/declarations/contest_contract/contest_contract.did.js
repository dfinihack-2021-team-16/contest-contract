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
    'submissions' : IDL.Vec(IDL.Tuple(IDL.Principal, IDL.Text)),
    'stake' : PlayTokenAmount,
  });
  const Decision = IDL.Opt(IDL.Principal);
  const Ballot = IDL.Record({ 'decision' : Decision, 'voter' : Judge });
  const ContestResults = IDL.Record({
    'contest' : Contest,
    'ballots' : IDL.Vec(IDL.Tuple(Judge, Ballot)),
    'winners' : IDL.Vec(IDL.Principal),
  });
  const ContestStatus = IDL.Record({
    'contest' : Contest,
    'ballots' : IDL.Vec(IDL.Tuple(Judge, Ballot)),
  });
  return IDL.Service({
    'check_and_maybe_resolve' : IDL.Func(
        [ContestId],
        [IDL.Opt(ContestResults)],
        [],
      ),
    'check_balances' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Principal, PlayTokenAmount))],
        ['query'],
      ),
    'faucet' : IDL.Func([ContestId, Decision], [], []),
    'lookup' : IDL.Func([ContestId], [IDL.Opt(ContestStatus)], ['query']),
    'make_contest' : IDL.Func([Contest], [IDL.Bool, IDL.Text], []),
    'vote' : IDL.Func([ContestId, Decision], [], []),
  });
};
export const init = ({ IDL }) => { return []; };
