import Map "mo:base/HashMap";
import List "mo:base/List";
import Array "mo:base/Array";
//import Option "mo:base/Option";


import Text "mo:base/Text";
import Time "mo:base/Time";
import PrincipalLib "mo:base/Principal";


/// Note on time:
/// We use the system time from motoko base library.
/// System time is represented as an Integral number of nanoseconds since 1970-01-01


actor {
  type PlayTokenAmount = Nat;
  type Ledger = Map.HashMap<Principal, PlayTokenAmount>;

  type ContestId = Text;
  type Phone = Text;
  public type Judge = Principal;
  type Decision = ?Principal;

  public type Ballot = {
    voter: Judge;
    decision: Decision;
  };

  type BallotMap = Map.HashMap<Judge, Ballot>;

  // Invariants
  // - each element of judges should be unique
  // - the keys in ballots should be a subset of judges.
  //
  // Note that even if a judge appears multiple times in judges, each judge still gets a single vote due to
  // implementation details.
  type ContestMut = {
    contest_id: ContestId;
    description: Text;
    judges: [Judge];
    submissions: [(Principal, Text)];
    ballots: BallotMap;
    decision_time: Time.Time;
    stake: PlayTokenAmount;
    default_receiver: Principal;  // who gets the funds if no winner
  };

  public type Contest = {
    contest_id: ContestId;
    description: Text;
    submissions: [(Principal, Text)];
    judges: [Judge];
    decision_time: Time.Time;
    stake: PlayTokenAmount;
    default_receiver: Principal;  // who gets the funds if no winner
  };

  public type ContestStatus = {
    contest: Contest;
    ballots: [(Judge, Ballot)];
  };

  public type ContestResults = {
    contest: Contest;
    ballots: [(Judge, Ballot)];
    winners: [Principal];
  };

  // internal function to create a shareable representation of contest.
  func freeze_ballots(ballots: BallotMap): [(Judge, Ballot)] {
    var ballots_array: [(Judge, Ballot)] = [];
    for (entry in ballots.entries()) {
      ballots_array := Array.append(ballots_array, Array.make(entry));
    };
    return ballots_array;
  };

  let contest_book = Map.HashMap<ContestId, (Contest, Map.HashMap<Judge, Ballot>)>(0, Text.equal, Text.hash);
  let ledger = Map.HashMap<Principal, PlayTokenAmount>(0, PrincipalLib.equal, PrincipalLib.hash);

  // returns whether creating the contest was successful
  public shared ({caller}) func make_contest(contest: Contest): async (Bool, Text) {
    switch (contest_book.get(contest.contest_id)) {
      case (?contest) {
        return (false, "The chosen contest_id already exists.");
      };
      case null {};
    };

    switch (ledger.get(caller)) {
      case null return (false, "The caller does not have enough funds.");
      case (?caller_balance) {
        if (contest.stake <= caller_balance) {
          ledger.put(caller, caller_balance - contest.stake);
          contest_book.put(contest.contest_id, (contest, Map.HashMap<Judge, Ballot>(0, PrincipalLib.equal, PrincipalLib.hash)));
          return (true, "Succeeded in creating contest.")
        } else {
          return (false, "The caller does not have enough funds.")
        };
      };
    };
  };

  public shared ({caller}) func vote(contest_id: ContestId, decision: Decision): async () {
    // dx note: it was hard to figure out how to handle Option types.
    switch (contest_book.get(contest_id)) {
      case null return;
      case (?(contest, ballots)) {
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
      case (?(contest, ballots)) {
        if (contest.decision_time <= Time.now()) {
          // TODO: calculate winners and disburse funds.
          var winners = [];

          return ?{
            contest = contest;
            ballots = freeze_ballots(ballots);
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
      case (?(contest, ballots)) {
        return ?{
          contest = contest;
          ballots = freeze_ballots(ballots);
        }
      }
    };
  };

  public shared ({caller}) func faucet(contest: ContestId, decision: Decision): async () {
    // add tokens to caller if they are a new user
  }
};
