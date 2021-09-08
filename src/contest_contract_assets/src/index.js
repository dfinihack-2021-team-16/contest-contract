import { contest_contract } from "../../declarations/contest_contract";
import { Principal } from '@dfinity/principal';

function $(id) {
  let el = document.getElementById(id);
  if (el == null) {
    throw new Error(`no element with id "${id}"`);
  }
  return el
}

const ME = Principal.fromText("zsszk-fc6es-7kxiu-hmzgn-lcslw-kxang-aiqg5-2q3fd-lvca7-ysjuz-tqe");

$("create-contest").addEventListener("submit", async (ev) => {
  ev.preventDefault();
  let form = ev.target;
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
    default_receiver: ME,
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
  let balances = await contest_contract.list_balances();

  let ser = balances.map(([p, b]) => [`${p.toHex().substr(0, 6)}...`, b.toString()]);

  $("balance").innerText = JSON.stringify(ser);
});

$("free_money").addEventListener("click", async () => {
  let [res, err] = await contest_contract.faucet();

  $("money").innerText = JSON.stringify({res,err});
})
