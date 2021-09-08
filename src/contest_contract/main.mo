import Map "mo:base/HashMap";
import List "mo:base/List";
import Array "mo:base/Array";
import TrieSet "mo:base/TrieSet";

//import Option "mo:base/Option";


import Text "mo:base/Text";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import PrincipalLib "mo:base/Principal";


/// Note on time:
/// We use the system time from motoko base library.
/// System time is represented as an Integral number of nanoseconds since 1970-01-01


actor {
  type PlayTokenAmount = Nat;
  type Ledger = Map.HashMap<Principal, PlayTokenAmount>;

  type ContestId = Text;
  public type Submission = Text;
  public type Judge = Principal;
  type Decision = ?Principal;

  public type Ballot = {
    voter: Judge;
    decision: Decision;
  };

  type SubmissionMap = Map.HashMap<Principal, Submission>;
  type BallotMap = Map.HashMap<Judge, Ballot>;

  // Invariants
  // - each element of judges should be unique
  // - the keys in ballots should be a subset of judges.
  //
  // Note that even if a judge appears multiple times in judges, each judge still gets a single vote due to
  // implementation details.
  public type Contest = {
    contest_id: ContestId;
    description: Text;
    judges: [Judge];
    decision_time: Time.Time;
    stake: PlayTokenAmount;
    default_receiver: Principal;  // who gets the funds if no winner
  };

  public type ContestStatus = {
    contest: Contest;
    submissions: [(Principal, Submission)];
    ballots: [(Judge, Ballot)];
    is_resolved: Bool;
  };

  public type ContestResults = {
    contest: Contest;
    submissions: [(Principal, Submission)];
    ballots: [(Judge, Ballot)];
    winners: [Principal];
  };

  public type JudgeReputation = Int;

  public type JudgeIntrinsicInfo = {
    friendly_name: Text;
    description: Text;
  };

  type JudgeMutableState = {
    reputation: JudgeReputation;
    judge_reputation_upvotes: TrieSet.Set<Principal>;
    judge_reputation_downvotes: TrieSet.Set<Principal>;
  };

  // internal function to create a shareable representation of ballots.
  func freeze_map<K, V>(mm: Map.HashMap<K, V>): [(K, V)] {
    var aa: [(K, V)] = [];
    for (entry in mm.entries()) {
      aa := Array.append(aa, Array.make(entry));
    };
    return aa;
  };

  // last bool is whether the contest is resolved.
  let contest_book = Map.HashMap<ContestId, (Contest, SubmissionMap, BallotMap, Bool)>(0, Text.equal, Text.hash);
  let ledger = Map.HashMap<Principal, PlayTokenAmount>(0, PrincipalLib.equal, PrincipalLib.hash);
  let registered_judges = Map.HashMap<Principal, (JudgeIntrinsicInfo, JudgeMutableState)>(0, PrincipalLib.equal, PrincipalLib.hash);

  // returns whether creating the contest was successful
  public shared ({caller}) func make_contest(contest: Contest): async (Bool, Text) {
    switch (contest_book.get(contest.contest_id)) {
      case (?anything) {
        return (false, "contest_id already exists");
      };
      case null {};
    };
    let (funding_successful, message) = debit(caller, contest.stake);
    if (funding_successful) {
      contest_book.put(contest.contest_id,
        (
          contest,
          Map.HashMap<Principal, Text>(0, PrincipalLib.equal, PrincipalLib.hash),
          Map.HashMap<Judge, Ballot>(0, PrincipalLib.equal, PrincipalLib.hash),
          false,
        )
      );
      return (true, "succeeded in creating contest")
    } else {
      return (false, message);
    };
  };

  public shared ({caller}) func submit(contest_id: ContestId, text: Text): async (Bool, Text) {
    switch (contest_book.get(contest_id)) {
      case null return (false, "contest_id not recognized");
      case (?(contest, submissions, ballots, is_resolved)) {
        if (not is_resolved and Time.now() < contest.decision_time) {
          switch (submissions.get(caller)) {
            case null {
              submissions.put(caller, text);
              return (true, "submission successful");
            };
            case (?submission) {
              return (false, "caller already submitted to this contest")
            };
          };
        } else {
          return (false, "contest is closed to submissions")
        };
      };
    };
  };

  public shared ({caller}) func vote(contest_id: ContestId, decision: Decision): async () {
    // dx note: it was hard to figure out how to handle Option types.
    switch (contest_book.get(contest_id)) {
      case null return;
      case (?(contest, submissions, ballots, is_resolved)) {
        if (not is_resolved and Array.find<Judge>(contest.judges, func (judge: Judge) { judge == caller }) != null) {
          ballots.put(caller, {voter = caller; decision = decision;});
          return;
        } else {
          return;
        }
      };
    };
  };

  // check if the contest is finished and resolve it if possible
  public shared func check_and_maybe_resolve(contest_id: ContestId): async ?ContestResults {
    // TODO: distinguish between failure modes in return value
    switch (contest_book.get(contest_id)) {
      case null return null;
      case (?(contest, submissions, ballots, is_resolved)) {
        if (not is_resolved and contest.decision_time <= Time.now()) {
          // tally votes
          let tallies = Map.HashMap<Principal, Nat>(0, PrincipalLib.equal, PrincipalLib.hash);
          for ((judge, ballot) in ballots.entries()) {
            switch (ballot.decision) {
              case null {};
              case (?contestant) {
                let old_tally = switch (tallies.get(contestant)) {
                  case null 0;
                  case (?val) val;
                };
                tallies.put(contestant, old_tally + 1);
              };
            };
          };

          // determine the winners
          var top: (Nat, [Principal]) = (0, []);
          for ((contestant, tally) in tallies.entries()) {
            if (top.0 < tally) {
              top := (tally, [contestant]);
            } else if (top.0 == tally) {
              top := (top.0, Array.append(top.1, Array.make(contestant)));
            } else {
              // nop
            };
          };
          let winners: [Principal] = top.1;
          let num_winners: Nat = Iter.size(Array.vals(winners));

          // disburse funds
          if (num_winners == 0) {
            let _ = credit(contest.default_receiver, contest.stake);
          } else {
            let prize_amount = contest.stake / num_winners;
            for (winner in Array.vals(winners)) {
              let _ = credit(winner, prize_amount);
            };
            let _ = credit(contest.default_receiver, num_winners * prize_amount);
          };

          // set is_resolved for the contest so it can't be resolved again
          contest_book.put(contest_id, (contest, submissions, ballots, true));

          return ?{
            contest = contest;
            submissions = freeze_map(submissions);
            ballots = freeze_map(ballots);
            winners = winners;
          };
        } else {
          return null;
        };
      };
    };
  };

  public shared query func lookup(contestId: ContestId) : async ?ContestStatus {
    switch (contest_book.get(contestId)) {
      case null return null;
      case (?(contest, submissions, ballots, is_resolved)) {
        return ?{
          contest = contest;
          submissions = freeze_map(submissions);
          ballots = freeze_map(ballots);
          is_resolved = is_resolved;
        }
      }
    };
  };

  public shared ({caller}) func send(receiver: Principal, amount: PlayTokenAmount): async (Bool, Text) {
    let (success, message) = debit(caller, amount);
    if (success) {
      let _ = credit(receiver, amount);
      return (true, "succeeded in sending play tokens")
    } else {
      return (false, message);
    };
  };

  func debit(account: Principal, amount: PlayTokenAmount): (Bool, Text) {
    if (amount <= 0) {
      return (false, "amount must be positive and nonzero");
    };
    switch (ledger.get(account)) {
      case null {
        return (false, "nonexistent account");
      };
      case (?balance) {
        if (amount <= balance) {
          ledger.put(account, balance - amount);
          return (true, "debited funds");
        } else {
          return (false, "insufficient funds")
        }
      };
    };
  };

  func credit(account: Principal, amount: PlayTokenAmount): (Bool, Text) {
    if (amount <= 0) {
      return (false, "amount must be positive and nonzero");
    };
    switch (ledger.get(account)) {
      case null {
        ledger.put(account, amount);
        return (true, "credited funds to new account");
      };
      case (?balance) {
        ledger.put(account, balance + amount);
        return (true, "credited funds");
      };
    };
  };

  public shared ({caller}) func register_as_judge(info: JudgeIntrinsicInfo): async () {
    let judge_state = switch (registered_judges.get(caller)) {
      case null {
        {
          reputation = 0;
          judge_reputation_downvotes = TrieSet.empty();
          judge_reputation_upvotes = TrieSet.empty();
        };
      };
      case (?(_, judge_state)) {
        judge_state;
      };
    };
    registered_judges.put(caller, (info, judge_state));
  };

  public shared query func list_judges(): async [(Judge, (JudgeIntrinsicInfo, JudgeReputation))] {
    var aa: [(Judge, (JudgeIntrinsicInfo, JudgeReputation))] = [];
    for ((judge, (judge_instric_info, judge_mutable_state)) in registered_judges.entries()) {
      aa := Array.append(aa, Array.make((judge, (judge_instric_info, judge_mutable_state.reputation))));
    };
    return aa;
  };

  func vote_on_judge_reputation(voter: Principal, judge: Judge, is_up: Bool): (Bool, Text) {
    let (success, message) = debit(voter, 100);
    if (not success) {
      return (false, message);
    };

    switch (registered_judges.get(judge)) {
      case null {};  // nop
      case (?(info, judge_state)) {
        var new_upvotes: TrieSet.Set<Principal> = judge_state.judge_reputation_upvotes;
        var new_downvotes: TrieSet.Set<Principal> = judge_state.judge_reputation_downvotes;
        if (is_up) {
          new_upvotes := TrieSet.put(judge_state.judge_reputation_upvotes, voter, PrincipalLib.hash(voter), PrincipalLib.equal);
        } else {
          new_downvotes := TrieSet.put(judge_state.judge_reputation_downvotes, voter, PrincipalLib.hash(voter), PrincipalLib.equal);
        };
        registered_judges.put(judge, (info,
          {
            reputation = TrieSet.size(new_upvotes) - TrieSet.size(new_downvotes);
            judge_reputation_upvotes = new_upvotes;
            judge_reputation_downvotes = new_downvotes;
          }));
      };
    };
    return (true, "")
  };

  public shared ({caller}) func upvote_judge_reputation(judge: Judge): async (Bool, Text) {
    vote_on_judge_reputation(caller, judge, true);
  };

  public shared ({caller}) func downvote_judge_reputation(judge: Judge): async (Bool, Text) {
    vote_on_judge_reputation(caller, judge, false);
  };

  public shared ({caller}) func faucet(): async (Bool, Text) {
    switch (ledger.get(caller)) {
      case null {
        let _ = credit(caller, 10000);
        return (true, "added funds");
      };
      case (?balance) {
        if (balance < 100) {
          let _ = credit(caller, 10000 - balance);
          return (true, "added funds");
        } else {
          return (false, "already have funds");
        };
      };
    };
  };

  public shared query func list_balances(): async [(Principal, PlayTokenAmount)] {
    return freeze_map(ledger);
  };
};
