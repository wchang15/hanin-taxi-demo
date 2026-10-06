
export const HUBADDRESS = process.env.REACT_APP_HUB_ADDRESS || 'http://localhost/Taxi';
export const APIADDRESS = process.env.REACT_APP_API_ADDRESS || 'http://localhost/api';
// export const APIADDRESS = 'http://localhost/api';
// 'http://localhost/api';


export const COMPANYTRIP = 'companytrip';
export const COMPANYCANCEL = 'companycancel';
export const MATCH = 'match';
export const UPDATEDRIVERLOCATION = 'updatedriverlocation';
export const TRIPSTART = 'tripstart';
export const TRIPCOMPLETE = 'tripcomplete';
export const DRIVERCANCEL = 'drivercancel';

export const TILE = 'https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png';
export const TILEAPI = process.env.REACT_APP_STADIA_MAPS_TILE_API || '';
