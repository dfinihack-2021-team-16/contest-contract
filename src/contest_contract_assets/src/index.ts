import { contest_contract } from "../../declarations/contest_contract";
import { Principal } from '@dfinity/principal';

function $(id: string): HTMLElement {
  return document.getElementById(id)
}

const PRINK = Principal.fromText("zsszk-fc6es-7kxiu-hmzgn-lcslw-kxang-aiqg5-2q3fd-lvca7-ysjuz-tqe");

$("create-contest").addEventListener("submit", async (ev) => {
  ev.preventDefault();
  let form = ev.target as HTMLFormElement;
  let contestDescription = form.description.value;
  let stake = parseInt(form.stake.value, 10);
  let end = Date.parse(form.endTime.value);
  if (isNaN(end)) {
    // TODO: complain to the user instead
    end = (new Date()).getTime();
  }

  // Date.parse produces seconds, while the backend accepts nanoseconds
  let end_ts = BigInt(end) * BigInt(1000000000);

  let [success, msg] = await contest_contract.make_contest({
    judges: [],
    decision_time: end_ts,
    contest_id: "my-neat-contest",
    default_receiver: PRINK,
    description: contestDescription,
    submissions: [],
    stake: BigInt(stake)
  });

  if (!success) {
    console.warn(msg);
  } else {
    console.log("success");
  }
});

$("get_balance").addEventListener("click", async () => {
  let balances = await contest_contract.check_balances();

  $("balance").innerText = JSON.stringify(balances);
})
