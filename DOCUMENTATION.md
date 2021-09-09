# IC Hack Contest Contract

A contract for setting up contests with decentralized trust.

## Core Features

- Each contest has a unique, immutable ID set by the creator of the contest. The ID can be any text that
  is not already taken by another contest. (And meets size limitations of the platform.)
- Each contest has a set of judges determined at initialization. This cannot be changed after the contest is created.
- Each contest has an amount of play-tokens that are staked by the creator of the contest as the prize.
- Each contest has a decision time. When the decision time is reached, when `check_and_maybe_resolve` method
  is called, the contest will be resolved in favor of the principal(s) with the highest number of votes (plurality)
  from judges.
- If there is a tie, the prize is split amongst the winners.
- The remainder of the prize not awarded to winners will be sent to the default receiver. The default receiver is
  set at contest creation, and cannot be changed. This can happen if there is no winner or if the prize amount is not
  divisible by the number of winners and there is a nonzero remainder.


## Optional Features

- Any user can make a submission to any contest. Each submission consists of a piece of text. This
  is intended to be a URL, but it can be any text. Judges can vote for any principal to win, so
  the contest can use an independent submission management system if desired.
- Users can send play-tokens to each other independently of contests.
- Judges can register a profile and set themselves a user-friendly name and description. 
  Each profile can build up a reputation over time.
- Any user can upvote or downvote a judge. Voting on judges costs a fee.

