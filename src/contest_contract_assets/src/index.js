import { contest_contract } from "../../declarations/contest_contract";

document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  // Interact with contest_contract actor, calling the greet method
  const greeting = await contest_contract.greet(name);

  document.getElementById("greeting").innerText = greeting;
});
