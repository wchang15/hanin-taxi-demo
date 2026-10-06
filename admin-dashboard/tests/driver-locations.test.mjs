import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeDrivers, validPosition } from '../src/utils/driverLocations.mjs';

test('positions require finite coordinates within geographic bounds', () => {
  assert.equal(validPosition({ latitude: 0, longitude: 0 }), true);
  for (const latitude of [null, undefined, '40', NaN, Infinity, 91, -91]) assert.equal(validPosition({ latitude, longitude: 0 }), false);
  for (const longitude of [null, undefined, '0', NaN, Infinity, 181, -181]) assert.equal(validPosition({ latitude: 40, longitude }), false);
});
test('response contains only API drivers with stable ordering and no mutation', () => {
  const rows = [{ driverID: 2, name: '2', isWorking: false, latitude: 0, longitude: 0 }, { driverID: 1, name: '<b>1</b>', isWorking: true, latitude: 40, longitude: -74 }];
  const original = JSON.stringify(rows);
  const drivers = normalizeDrivers(rows);
  assert.equal(drivers.length, 2); assert.equal(drivers[0].driverID, 1); assert.equal(drivers[0].hasPosition, true); assert.equal(drivers[1].hasPosition, false);
  assert.equal(JSON.stringify(rows), original);
});
test('empty, duplicate and invalid rows do not introduce fake markers', () => {
  assert.deepEqual(normalizeDrivers([]), []);
  assert.throws(() => normalizeDrivers({}));
  assert.equal(normalizeDrivers([null, { driverID: 1 }, { driverID: 1 }]).length, 1);
  assert.equal(normalizeDrivers([{ driverID: 1, isWorking: true, latitude: null, longitude: null }])[0].hasPosition, false);
});
