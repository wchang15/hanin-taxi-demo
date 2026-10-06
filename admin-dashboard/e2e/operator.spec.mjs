import { test as base, expect } from '@playwright/test';

const test = base.extend({
  runtimeGuard: [
    async ({ page }, use) => {
      const errors = [];
      page.on('pageerror', (error) => errors.push(error.message));
      page.on('response', (response) => {
        if (response.url().startsWith('http://127.0.0.1:5796/') && response.status() >= 500) {
          errors.push(`API server error: ${response.status()}`);
        }
      });
      await use();
      expect(errors).toEqual([]);
    },
    { auto: true },
  ],
});

async function signIn(page) {
  await page.goto('/login');
  await page.locator('input[name="account"]').fill('demo_company');
  await page.locator('input[name="password"]').fill('demo1234');
  await page.locator('button[type="submit"]').click();
  await expect(page).toHaveURL(/\/dashboard\/app$/);
}

test('anonymous nested route returns to sign-in', async ({ page }) => {
  await page.goto('/dashboard/taxi');
  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByRole('heading', { name: 'Sign in to Hanin Taxi' })).toBeVisible();
});

test('operator signs in, opens dispatch, and reloads a nested route', async ({ page }, testInfo) => {
  await signIn(page);
  await page.goto('/dashboard/taxi');
  await expect(page.getByRole('heading', { name: 'Live Dispatch' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'New call' })).toBeVisible();
  await page.reload();
  await expect(page.getByRole('heading', { name: 'Live Dispatch' })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('dispatch.png'), fullPage: true });
  const size = await page.evaluate(() => ({
    width: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth,
  }));
  expect(size.scroll).toBeLessThanOrEqual(size.width);
});

test('new call opens the dispatch form', async ({ page }, testInfo) => {
  await signIn(page);
  await page.goto('/dashboard/taxi');
  await page.getByRole('button', { name: 'New call' }).click();
  await expect(page.getByRole('combobox').first()).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('new-call.png'), fullPage: true });
});

test('incorrect credentials allow a second attempt', async ({ page }) => {
  await page.goto('/login');
  await page.locator('input[name="password"]').fill('incorrect-demo-password');
  await page.locator('button[type="submit"]').click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.locator('button[type="submit"]')).toBeEnabled();
  await page.locator('input[name="password"]').fill('demo1234');
  await page.locator('button[type="submit"]').click();
  await expect(page).toHaveURL(/\/dashboard\/app$/);
});

test('network failure leaves a usable sign-in form', async ({ page }) => {
  await page.route('**/api/Login/LoginCompany', (route) => route.abort('connectionrefused'));
  await page.goto('/login');
  await page.locator('button[type="submit"]').click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.locator('button[type="submit"]')).toBeEnabled();
});

test('sign-out clears stored session and blocks a protected route', async ({ page }) => {
  await signIn(page);
  await page.getByRole('button', { name: 'Account menu' }).click();
  await page.getByRole('menuitem', { name: '로그아웃' }).click();
  await expect(page).toHaveURL(/\/login$/);
  const hasSession = await page.evaluate(() => {
    const state = JSON.parse(localStorage.getItem('taxis') || '{}').state;
    return Boolean(state?.jwtToken || state?.refreshToken || state?.company);
  });
  expect(hasSession).toBe(false);
  await page.goto('/dashboard/taxi');
  await expect(page).toHaveURL(/\/login$/);
});

test('offline sign-out still leaves the protected UI', async ({ page }) => {
  await signIn(page);
  await page.route('**/api/Login/Logout', (route) => route.abort('connectionrefused'));
  await page.getByRole('button', { name: 'Account menu' }).click();
  await page.getByRole('menuitem', { name: '로그아웃' }).click();
  await expect(page).toHaveURL(/\/login$/);
  await page.goto('/dashboard/taxi');
  await expect(page).toHaveURL(/\/login$/);
});

test('driver map loads API positions, preserves the viewport and supports refresh', async ({ page }, testInfo) => {
  await signIn(page);
  let requests = 0;
  await page.route('**/api/Company/GetCompanyDriverLocations', async (route) => {
    requests++;
    await route.fulfill({ json: [{ driverID: 1, name: '101', isWorking: true, latitude: 40.8482, longitude: -73.9976 }] });
  });
  await page.goto('/dashboard/map');
  await expect(page.getByRole('heading', { name: 'Driver Map' })).toBeVisible();
  await expect(page.getByRole('status')).toContainText('1 located / 1 drivers');
  await expect(page.getByText('Example1')).toHaveCount(0);
  await page.getByRole('button', { name: 'Locate driver 101' }).click();
  await page.getByRole('button', { name: 'Refresh driver locations' }).click();
  await expect.poll(() => requests).toBeGreaterThanOrEqual(2);
  await expect.poll(() => requests, { timeout: 15000 }).toBeGreaterThanOrEqual(3);
  await expect(page.getByRole('button', { name: 'Locate driver 101' })).toHaveClass(/Mui-selected/);
  const size = await page.evaluate(() => ({ width: document.documentElement.clientWidth, scroll: document.documentElement.scrollWidth }));
  expect(size.scroll).toBeLessThanOrEqual(size.width);
  await page.screenshot({ path: testInfo.outputPath('driver-map.png'), fullPage: true });
});

test('map empty and error states recover without injected drivers', async ({ page }) => {
  await signIn(page);
  let offline = false;
  await page.route('**/api/Company/GetCompanyDriverLocations', (route) => offline ? route.abort('connectionrefused') : route.fulfill({ json: [] }));
  await page.goto('/dashboard/map');
  await expect(page.getByText('No drivers are currently sharing a location.')).toBeVisible();
  offline = true;
  await page.getByRole('button', { name: 'Refresh driver locations' }).click();
  await expect(page.getByText(/Driver locations could not be refreshed/)).toBeVisible();
  offline = false;
  await page.getByRole('button', { name: 'Retry', exact: true }).click();
  await expect(page.getByText('No drivers are currently sharing a location.')).toBeVisible();
});
