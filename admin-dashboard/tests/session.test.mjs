import assert from 'node:assert/strict';
import { test } from 'node:test';

const values = new Map();
globalThis.localStorage = {
  getItem: (key) => values.get(key) ?? null,
  setItem: (key, value) => values.set(key, String(value)),
  removeItem: (key) => values.delete(key),
};
globalThis.document = { cookie: '' };
const { default: userStore } = await import('../src/store/userStore.js');

test('sign-out clears both in-memory and persisted identity', () => {
  userStore.getState().setUser({
    company: { name: 'Synthetic company' },
    token: 'synthetic-access-token',
    refreshToken: 'synthetic-refresh-token',
  });
  assert.ok(userStore.getState().jwtToken);
  userStore.getState().reset();
  const current = userStore.getState();
  const persisted = JSON.parse(localStorage.getItem('taxis')).state;
  for (const state of [current, persisted]) {
    assert.equal(Boolean(state.jwtToken || state.refreshToken || state.company), false);
  }
  assert.match(document.cookie, /^refreshToken=;/);
});
