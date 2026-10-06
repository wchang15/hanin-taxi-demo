import { Helmet } from 'react-helmet-async';
import { Grid, Typography, Box, Button } from '@mui/material';
import React, { useEffect, useState } from 'react';
import CircleIcon from '@mui/icons-material/Circle';
import { MapContainer, TileLayer, useMap } from 'react-leaflet';
import L from 'leaflet';
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';
import LoadingButton from '@mui/lab/LoadingButton';
import { grey } from '@mui/material/colors';
import { TILE, TILEAPI } from '../utils/constants';
import { debounce } from '../utils/helper';
import userStore from '../store/userStore';
import hydrationStore from '../store/hydrationStore';
import apiService from '../components/apiService/apiService';
import 'leaflet.markercluster';

const DefaultIcon = L.icon({
  iconUrl: icon,
  shadowUrl: iconShadow,
});

L.Marker.prototype.options.icon = DefaultIcon;

export default function MapPage({ setIsLoading }) {
  const company = hydrationStore(userStore, (state) => state.company);
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);
  const [drivers, setDrivers] = useState([]);
  // center of the map (Company location)
  const [center, setCenter] = useState([]);

  const getDriverLocations = debounce(async () => {
    try {
      if (company && jwtToken) {
        const res = await apiService().get(`/Company/GetCompanyDriverLocations`, {
          headers: {
            Authorization: `Bearer ${jwtToken}`,
            'Content-Type': 'application/json',
          },
        });

        if (res && res.status === 200) {
          console.log(res.data);
          const data = res.data;
          // TODO: Remove this
          data.push(
            { driverID: 1, name: 'Example1', latitude: 40.8482, longitude: -73.9976, isWorking: true },
            { driverID: 2, name: 'Example2', latitude: 40.8509, longitude: -73.9701, isWorking: true },
            { driverID: 3, name: 'Example3', latitude: 42.8142, longitude: -73.9396, isWorking: true },
            { driverID: 4, name: 'Example4', latitude: 42.8142, longitude: -73.9396, isWorking: false }
          );
          data.sort((a, b) => {
            if (a.isWorking < b.isWorking) return 1;
            if (a.isWorking > b.isWorking) return -1;
            return 0;
          });
          const temp = [];
          data.forEach((driver) => {
            const randomColor = () => Math.floor(Math.random() * 16777215).toString(16);
            driver = { ...driver, color: randomColor() };
            temp.push(driver);
          });
          setDrivers(temp);
        }
      }
    } catch (err) {
      console.log(err);
    }
    setIsLoading(false);
  }, 500);

  useEffect(() => {
    if (company && jwtToken) {
      updateMap();
    }
  }, [company, jwtToken]);

  useEffect(() => {
    // TODO: This should be company specific // Palisades park
    setCenter([40.8482, -73.9976]);
  }, [company]);

  const updateMap = async () => {
    setIsLoading(true);
    // Empty the Drivers
    setDrivers([]);
    getDriverLocations();
  };

  return (
    <>
      <Helmet>
        <title> Map | Hanin Taxi </title>
      </Helmet>

      <Grid container>
        <Grid item xs={10.5} sx={{ px: 3 }}>
          {company !== undefined ? (
            <MapContainer style={{ width: '100%', height: '85vh' }} center={center} zoom={13} scrollWheelZoom={false}>
              <ChangeView center={center} zoom={13} />
              <TileLayer url={`${TILE}?${TILEAPI}`} />
              <ColorMarkers drivers={drivers} />
            </MapContainer>
          ) : null}
        </Grid>
        <Grid item xs={1.5}>
          <LoadingButton
            fullWidth
            color={'primary'}
            variant="contained"
            // loading={isLoading}
            sx={{ color: '#FFFFFF', mb: 3 }}
            onClick={updateMap}
          >
            지도 업데이트
          </LoadingButton>
          {drivers.map((driver, index) => (
            <Box
              key={index}
              sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mr: 2, mb: 2 }}
            >
              {driver.isWorking ? (
                <Button
                  variant={'text'}
                  sx={{ p: 0 }}
                  onClick={() => {
                    console.log([driver.latitude, driver.longitude]);
                    setCenter([driver.latitude, driver.longitude]);
                  }}
                >
                  <Typography color={grey[900]} align="left">
                    {driver.name}
                  </Typography>
                </Button>
              ) : (
                <Typography color={grey[400]} align="left">
                  {driver.name}
                </Typography>
              )}

              {driver.isWorking ? <CircleIcon sx={{ color: `#${driver.color}` }} /> : null}
            </Box>
          ))}
        </Grid>
      </Grid>
    </>
  );
}

const ColorMarkers = ({ drivers }) => {
  const map = useMap();
  useEffect(() => {
    if (!map) return;

    const colorMarker = () => {
      const markers = L.markerClusterGroup();

      removeMarkers();

      drivers.forEach((driver) => {
        if (!driver.isWorking) return;
        const icon = new L.DivIcon({
          className: 'custom-icon-marker',
          iconSize: L.point(40, 40),
          html: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" class="marker"><path fill-opacity="0.25" d="M16 32s1.427-9.585 3.761-12.025c4.595-4.805 8.685-.99 8.685-.99s4.044 3.964-.526 8.743C25.514 30.245 16 32 16 32z"/><path stroke="#fff" fill="#${driver.color}" d="M15.938 32S6 17.938 6 11.938C6 .125 15.938 0 15.938 0S26 .125 26 11.875C26 18.062 15.938 32 15.938 32zM16 6a4 4 0 100 8 4 4 0 000-8z"/></svg>`,
          iconAnchor: [12, 24],
          popupAnchor: [9, -26],
        });

        const marker = L.marker([driver.latitude, driver.longitude], { icon }).bindPopup(`${driver.name}`);
        markers.addLayer(marker);
      });
      map.addLayer(markers);
    };
    function removeMarkers() {
      map.eachLayer((layer) => {
        if (layer instanceof L.MarkerClusterGroup) {
          map.removeLayer(layer);
        }
      });
    }

    colorMarker();
  }, [map, drivers]);
  return null;
};

const ChangeView = ({ center, zoom }) => {
  const map = useMap();
  map.setView(center, zoom);
  return null;
};
