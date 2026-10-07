import assert from "node:assert/strict";
import net from "node:net";
import { setTimeout as delay } from "node:timers/promises";
import { startDemo } from "./start-demo.mjs";

const probe = net.createServer();
await new Promise((resolve, reject) => {
  probe.once("error", reject);
  probe.listen(0, "127.0.0.1", resolve);
});
const port = probe.address().port;
await new Promise((resolve) => probe.close(resolve));
const base = `http://127.0.0.1:${port}`;
const child = startDemo({
  port,
  autoMatch: false,
  noBuild: true,
  stdio: ["ignore", "pipe", "pipe"],
});
let output = "";
let startupError;
let exited = false;
const closed = new Promise((resolve) => {
  child.on("error", (error) => {
    startupError = error;
    exited = true;
    resolve();
  });
  child.on("exit", () => {
    exited = true;
    resolve();
  });
});
for (const stream of [child.stdout, child.stderr])
  stream.on("data", (data) => {
    output = (output + data).slice(-6000);
  });
let checks = 0;
function check(name, fn) {
  fn();
  checks++;
  console.log(`PASS ${name}`);
}
async function call(route, { method = "GET", token, body, status = 200 } = {}) {
  const response = await fetch(`${base}/api/${route}`, {
    method,
    headers: {
      ...(body ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(10000),
  });
  const text = await response.text();
  assert.equal(response.status, status, `${route}: unexpected HTTP status`);
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

try {
  let ready = false;
  for (let attempt = 0; attempt < 120; attempt++) {
    if (startupError) throw startupError;
    if (exited)
      throw new Error(`Demo process stopped before readiness.\n${output}`);
    try {
      const response = await fetch(`${base}/api/Demo/Status`, {
        signal: AbortSignal.timeout(1000),
      });
      if (response.ok) {
        const status = await response.json();
        check("isolated in-memory demo, no external payments", () => {
          assert.equal(status.demoMode, true);
          assert.equal(status.persistence, "in-memory");
          assert.equal(status.externalPayments, false);
        });
        ready = true;
        break;
      }
    } catch {}
    await delay(250);
  }
  assert.ok(ready, "Demo did not start; run the Release build first.");
  await call("Trip/CurrentTripCustomer", { status: 401 });
  check("anonymous trip access denied", () => {});
  const customer = await call("Login/LoginCustomer", {
    method: "POST",
    body: { username: "demo_customer", password: "demo1234" },
  });
  const driver = await call("Login/LoginDriver", {
    method: "POST",
    body: { username: "demo_driver", password: "demo1234" },
  });
  check("rider and driver sign in", () => {
    assert.ok(customer.token);
    assert.ok(driver.token);
  });
  await call("Trip/CurrentTripCustomer", { token: driver.token, status: 403 });
  check("driver cannot use rider-only trip endpoint", () => {});
  const locations = await call("Shared/GetAutoComplete?address=airport", {
    token: customer.token,
  });
  check("seeded airport lookup", () => assert.ok(locations.length >= 3));
  const pickup = {
    pickupName: "Hanin Taxi Demo Office",
    pickupAddress: "Fort Lee, NJ 07024",
    pickupLongitude: -73.9701,
    pickupLatitude: 40.8509,
    pickupLocationType: 7,
  };
  const destination = {
    dropoffName: "John F. Kennedy International Airport",
    dropoffAddress: "Queens, NY 11430",
    dropoffLongitude: -73.7781,
    dropoffLatitude: 40.6413,
    dropoffLocationType: 1,
  };
  const trip = await call("Trip/NewTrip", {
    method: "POST",
    token: customer.token,
    body: { ...pickup, ...destination },
  });
  check("Fort Lee-to-JFK quote", () => {
    assert.equal(trip.smallTaxiFee, "$44.07");
    assert.equal(trip.largeTaxiFee, "$47.07");
  });
  await call("DriverQueue/EnqueueDriver", {
    method: "POST",
    token: driver.token,
    body: { latitude: 40.851, longitude: -73.97 },
  });
  await call("Trip/ConfirmTrip", {
    method: "POST",
    token: customer.token,
    body: {
      tripID: trip.tripID,
      customerCardID: 0,
      enumTaxiSize: 1,
      enumPaymentType: 4,
    },
  });
  // Both matching entry points respect the two-second enqueue cooldown.
  await delay(2100);
  const dispatch = await call("Demo/RunDispatch", { method: "POST" });
  check("eligible driver matched to quoted trip", () => {
    assert.equal(dispatch.matched, true);
    assert.equal(dispatch.policy, "company-round-robin");
    assert.equal(dispatch.tripID, trip.tripID);
  });
  await call("DriverQueue/MatchTrip", { method: "POST", token: driver.token });
  await call("Trip/StartTrip", {
    method: "POST",
    token: driver.token,
    body: destination,
  });
  const driverTrip = await call("DriverQueue/GetDriverQueueStatus", {
    token: driver.token,
  });
  const completed = await call("Trip/CompleteTrip", {
    method: "POST",
    token: driver.token,
  });
  check("same trip reaches COMPLETED", () => {
    assert.equal(completed.tripID, trip.tripID);
    assert.equal(completed.tripStatus, 6);
  });
  const paid = await call("Payment/CompletePayment?tip=0", {
    method: "POST",
    token: customer.token,
  });
  check("cash settlement preserves quoted fare", () => {
    assert.equal(driverTrip.tripID, trip.tripID);
    assert.equal(driverTrip.tripAmount, 44.07);
    assert.equal(paid.fullAmount, 44.07);
    assert.equal(paid.paymentStatus, 2);
    assert.equal(paid.paymentType, 4);
  });
  await call("Trip/CurrentTripCustomer", {
    token: customer.token,
    status: 400,
  });
  check("rider has no remaining current trip", () => {});
  console.log(
    `${checks} isolated API checks passed. No running user demo was touched.`
  );
} finally {
  if (!exited) child.kill("SIGTERM");
  await Promise.race([closed, delay(5000)]);
  if (!exited) {
    child.kill("SIGKILL");
    await closed;
  }
}
