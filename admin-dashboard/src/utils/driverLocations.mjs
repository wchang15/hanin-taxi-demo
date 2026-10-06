export function validPosition(driver) {
  return typeof driver?.latitude === 'number' && Number.isFinite(driver.latitude) && Math.abs(driver.latitude) <= 90
    && typeof driver?.longitude === 'number' && Number.isFinite(driver.longitude) && Math.abs(driver.longitude) <= 180;
}

export function normalizeDrivers(rows) {
  if (!Array.isArray(rows)) throw new Error('Invalid driver response');
  const seen = new Set();
  return rows.filter((driver) => {
    if (!driver || driver.driverID == null || seen.has(driver.driverID)) return false;
    seen.add(driver.driverID);
    return true;
  }).map((driver) => ({
    ...driver, name: String(driver.name ?? driver.driverID),
    hasPosition: driver.isWorking === true && validPosition(driver),
  })).sort((a, b) => Number(b.isWorking === true) - Number(a.isWorking === true) || a.name.localeCompare(b.name, 'en', { numeric: true }));
}
