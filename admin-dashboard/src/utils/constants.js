
export const HUBADDRESS = import.meta.env.VITE_HUB_ADDRESS || 'http://127.0.0.1:5050/Taxi';
export const APIADDRESS = import.meta.env.VITE_API_ADDRESS || 'http://127.0.0.1:5050/api';


export const COMPANYTRIP = 'companytrip';
export const COMPANYCANCEL = 'companycancel';
export const MATCH = 'match';
export const UPDATEDRIVERLOCATION = 'updatedriverlocation';
export const TRIPSTART = 'tripstart';
export const TRIPCOMPLETE = 'tripcomplete';
export const DRIVERCANCEL = 'drivercancel';

export const TILE = 'https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png';
export const TILEAPI = import.meta.env.VITE_STADIA_MAPS_TILE_API || '';
