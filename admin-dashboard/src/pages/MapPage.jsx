import { Helmet } from 'react-helmet-async';
import { Alert, Box, Button, CircularProgress, IconButton, List, ListItemButton, ListItemText, Tooltip, Typography } from '@mui/material';
import RefreshIcon from '@mui/icons-material/Refresh';
import MyLocationIcon from '@mui/icons-material/MyLocation';
import React, { useEffect, useRef, useState } from 'react';
import { CircleMarker, MapContainer, Popup, TileLayer, useMap } from 'react-leaflet';
import { TILE, TILEAPI } from '../utils/constants';
import { normalizeDrivers, validPosition } from '../utils/driverLocations.mjs';
import userStore from '../store/userStore';
import hydrationStore from '../store/hydrationStore';
import apiService from '../components/apiService/apiService';

export default function MapPage() {
  const company = hydrationStore(userStore, (state) => state.company);
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [updatedAt, setUpdatedAt] = useState(null);
  const [focus, setFocus] = useState(null);
  const [fitRequest, setFitRequest] = useState(0);
  const refresh = useRef(() => {});
  const companyID = company?.companyID;

  useEffect(() => {
    if (!jwtToken || !companyID) return undefined;
    let disposed = false;
    let pending = false;
    let timer;
    let controller;
    const load = async () => {
      if (disposed || pending) return;
      clearTimeout(timer);
      pending = true;
      controller = new AbortController();
      setLoading(true);
      try {
        const { data } = await apiService().get('/Company/GetCompanyDriverLocations', {
          headers: { Authorization: `Bearer ${jwtToken}` }, signal: controller.signal, timeout: 8000,
        });
        if (!disposed) {
          setDrivers(normalizeDrivers(data)); setUpdatedAt(new Date()); setError('');
        }
      } catch {
        if (!disposed) setError('Driver locations could not be refreshed. Showing the last received positions.');
      } finally {
        pending = false;
        if (!disposed) { setLoading(false); timer = setTimeout(load, 10000); }
      }
    };
    setDrivers([]); setUpdatedAt(null); setError(''); setFocus(null);
    refresh.current = load;
    load();
    return () => { disposed = true; clearTimeout(timer); controller?.abort(); refresh.current = () => {}; };
  }, [companyID, jwtToken]);

  const located = drivers.filter((driver) => driver.hasPosition);
  const center = validPosition(company) ? [company.latitude, company.longitude] : [40.75, -74];
  return (
    <>
      <Helmet><title>Driver Map | Hanin Taxi</title></Helmet>
      <Box sx={{ px: { xs: 2, md: 3 }, pb: 3, minWidth: 0 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2, mb: 2 }}>
          <Box>
            <Typography variant="h4" component="h1">Driver Map</Typography>
            <Typography variant="body2" color="text.secondary" role="status">
              {located.length} located / {drivers.length} drivers
              {updatedAt ? ` · Last fetched ${updatedAt.toLocaleTimeString('en-US')}` : ' · Waiting for locations'}
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1, flexShrink: 0 }}>
            <Tooltip title="Show all drivers"><span><IconButton aria-label="Show all drivers" disabled={!located.length} onClick={() => { setFocus(null); setFitRequest((n) => n + 1); }}><MyLocationIcon /></IconButton></span></Tooltip>
            <Tooltip title="Refresh driver locations"><span><IconButton aria-label="Refresh driver locations" disabled={loading} onClick={() => refresh.current()}>{loading ? <CircularProgress size={22} /> : <RefreshIcon />}</IconButton></span></Tooltip>
          </Box>
        </Box>
        {error && <Alert severity="warning" sx={{ mb: 2 }} action={<Button color="inherit" size="small" disabled={loading} onClick={() => refresh.current()}>Retry</Button>}>{error}</Alert>}
        {!loading && !error && !located.length && <Alert severity="info" sx={{ mb: 2 }}>No drivers are currently sharing a location.</Alert>}
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'minmax(0, 1fr)', md: 'minmax(0, 1fr) 240px' }, gap: 2 }}>
          <Box role="region" aria-label="Driver locations map" sx={{ height: { xs: '52vh', md: '68vh' }, minHeight: 300, minWidth: 0, overflow: 'hidden', borderRadius: 1, border: '1px solid', borderColor: 'divider' }}>
            <MapContainer center={center} zoom={12} scrollWheelZoom style={{ width: '100%', height: '100%' }}>
              <TileLayer url={TILEAPI ? `${TILE}?${TILEAPI}` : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'} attribution={TILEAPI ? '&copy; Stadia Maps &copy; OpenMapTiles &copy; OpenStreetMap' : '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'} />
              <MapView drivers={located} focus={focus} fitRequest={fitRequest} companyID={companyID} />
              {located.map((driver) => <CircleMarker key={driver.driverID} center={[driver.latitude, driver.longitude]} radius={9} pathOptions={{ color: '#ffffff', weight: 3, fillColor: '#087f8c', fillOpacity: 1 }}>
                <Popup><strong>Driver {driver.name}</strong><br />On duty</Popup>
              </CircleMarker>)}
            </MapContainer>
          </Box>
          <Box component="aside" sx={{ minWidth: 0 }} aria-label="Drivers">
            <Typography variant="subtitle1" component="h2">Fleet</Typography>
            <List dense disablePadding sx={{ maxHeight: { xs: 240, md: '60vh' }, overflowY: 'auto' }}>
              {drivers.map((driver) => <ListItemButton key={driver.driverID} disabled={!driver.hasPosition} selected={focus?.driverID === driver.driverID} onClick={() => setFocus({ ...driver })} aria-label={`Locate driver ${driver.name}`} sx={{ px: 1, borderBottom: '1px solid', borderColor: 'divider' }}>
                <ListItemText primary={`Driver ${driver.name}`} secondary={driver.hasPosition ? 'On duty' : driver.isWorking ? 'Location unavailable' : 'Off duty'} primaryTypographyProps={{ sx: { overflowWrap: 'anywhere' } }} />
              </ListItemButton>)}
            </List>
          </Box>
        </Box>
      </Box>
    </>
  );
}

function MapView({ drivers, focus, fitRequest, companyID }) {
  const map = useMap();
  const fitted = useRef(false);
  useEffect(() => { fitted.current = false; }, [companyID, fitRequest]);
  useEffect(() => {
    if (!fitted.current && drivers.length) {
      map.fitBounds(drivers.map((driver) => [driver.latitude, driver.longitude]), { padding: [35, 35], maxZoom: 14 });
      fitted.current = true;
    }
  }, [map, drivers, fitRequest]);
  useEffect(() => {
    if (focus) map.setView([focus.latitude, focus.longitude], 16);
  }, [map, focus]);
  useEffect(() => {
    const observer = new ResizeObserver(() => map.invalidateSize());
    observer.observe(map.getContainer());
    return () => observer.disconnect();
  }, [map]);
  return null;
}
