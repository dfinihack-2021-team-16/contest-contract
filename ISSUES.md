# Known Issues

## Upvotes and downvotes cannot be canceled

A user cannot remove their upvote or downvote. They can, however, both upvote
and downvote the same judge, which means the votes cancel each other out.


## Judges are not unique in the array of judges

Not a major issue since the array of judges is just used to determine if a
judge can vote on a contest. If the judge is in the array twice, they do
not get more than one vote. However, having the same judge appear twice may be
confusing.


## Scalability

A number of scalability issues exist:

- number contests kept in memory
- size of judge list for each contest
- number of submissions for each contest
- size of contest ID and description
- size of the user-friendly name and description for a judge's profile
- number of upvotes and downvotes on each judge
- number of accounts in the ledger
