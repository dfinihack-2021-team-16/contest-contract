import Map "mo:base/HashMap";
import List "mo:base/List";
import Array "mo:base/Array";
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
  };

  public type ContestResults = {
    contest: Contest;
    submissions: [(Principal, Submission)];
    ballots: [(Judge, Ballot)];
    winners: [Principal];
  };

  // internal function to create a shareable representation of ballots.
  func freeze_map<K, V>(mm: Map.HashMap<K, V>): [(K, V)] {
    var aa: [(K, V)] = [];
    for (entry in mm.entries()) {
      aa := Array.append(aa, Array.make(entry));
    };
    return aa;
  };

  let contest_book = Map.HashMap<ContestId, (Contest, SubmissionMap, BallotMap)>(0, Text.equal, Text.hash);
  let ledger = Map.HashMap<Principal, PlayTokenAmount>(0, PrincipalLib.equal, PrincipalLib.hash);

  // returns whether creating the contest was successful
  public shared ({caller}) func make_contest(contest: Contest): async (Bool, Text) {
    switch (contest_book.get(contest.contest_id)) {
      case (?anything) {
        return (false, "contest_id already exists");
      };
      case null {};
    };

    switch (ledger.get(caller)) {
      case null return (false, "caller does not have enough funds");
      case (?caller_balance) {
        if (contest.stake <= caller_balance) {
          ledger.put(caller, caller_balance - contest.stake);
          contest_book.put(contest.contest_id,
            (
              contest,
              Map.HashMap<Principal, Text>(0, PrincipalLib.equal, PrincipalLib.hash),
              Map.HashMap<Judge, Ballot>(0, PrincipalLib.equal, PrincipalLib.hash)
            ));
          return (true, "succeeded in creating contest")
        } else {
          return (false, "caller does not have enough funds")
        };
      };
    };
  };

  /// The text in the submission is intended to be a url. A principal can only submit once to each contest.
  public shared ({caller}) func submit(contest_id: ContestId, text: Text): async (Bool, Text) {
    switch (contest_book.get(contest_id)) {
      case null return (false, "contest_id not recognized");
      case (?(contest, submissions, ballots)) {
        if (Time.now() < contest.decision_time) {
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
      case (?(contest, submissions, ballots)) {
        if (Array.find<Judge>(contest.judges, func (judge: Judge) { judge == caller }) != null) {
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
      case (?(contest, submissions, ballots)) {
        if (contest.decision_time <= Time.now()) {

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
          let prize_amount = contest.stake / num_winners;
          for (winner in Array.vals(winners)) {
            let _ = credit(winner, prize_amount);
          };
          let _ = credit(contest.default_receiver, num_winners * prize_amount);

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
      case (?(contest, submissions, ballots)) {
        return ?{
          contest = contest;
          submissions = freeze_map(submissions);
          ballots = freeze_map(ballots);
        }
      }
    };
  };

  func credit(account: Principal, amount: PlayTokenAmount): (Bool, Text) {
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

  public shared ({caller}) func faucet(contest: ContestId, decision: Decision): async (Bool, Text) {
    // add tokens to caller if they are a new user
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
};

