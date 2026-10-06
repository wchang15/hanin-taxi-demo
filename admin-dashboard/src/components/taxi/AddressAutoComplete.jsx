import { useState, useEffect } from 'react';
import { TextField, Autocomplete, Box, Typography } from '@mui/material';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import LocalAirportIcon from '@mui/icons-material/LocalAirport';
import RestaurantIcon from '@mui/icons-material/Restaurant';
import StoreIcon from '@mui/icons-material/Store';
import ParkIcon from '@mui/icons-material/Park';
import SchoolIcon from '@mui/icons-material/School';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';
import { EnumLocationType } from '../../_mock/taxi';
import { debounce, getLocationName } from '../../utils/helper';
import apiService from '../apiService/apiService';

export default function AddressAutoComplete({ handleSelect, jwtToken, refresh, placeHolder = null, required }) {
  const [options, setOptions] = useState([]);
  const [key, setKey] = useState(1);

  useEffect(() => {
    setOptions([]);
    setKey(key + 1);
  }, [refresh]);

  const handleInputChange = debounce(async (event) => {
    const searchTerm = event.target.value;
    if (searchTerm !== '') {
      const response = await apiService().get(`/Shared/GetAutoComplete?address=${searchTerm}`, {
        headers: {
          Authorization: `Bearer ${jwtToken}`,
          'Content-Type': 'application/json',
        },
      });
      if (response !== null && response.status === 200) {
        const data = response.data;
        setOptions(data);
      }
    }
  }, 300);

  const locationTypeIcon = [
    { type: EnumLocationType.AIRPORT, icon: <LocalAirportIcon /> },
    { type: EnumLocationType.RESTAURANT, icon: <RestaurantIcon /> },
    { type: EnumLocationType.STORE, icon: <StoreIcon /> },
    { type: EnumLocationType.PARK, icon: <ParkIcon /> },
    { type: EnumLocationType.SCHOOL, icon: <SchoolIcon /> },
    { type: EnumLocationType.HOSPITAL, icon: <LocalHospitalIcon /> },
    { type: EnumLocationType.OTHER, icon: <LocationOnIcon /> },
  ];

  const getIcon = (locationType) => {
    return locationTypeIcon.find((x) => x.type === locationType)?.icon ?? <LocationOnIcon />;
  };

  return (
    <Autocomplete
      key={key}
      fullWidth
      options={options}
      getOptionLabel={(option) => getLocationName(option.preferredName, option.name, option.address)}
      onChange={(event, value) => {
        handleSelect(value);
      }}
      filterOptions={(x) => x}
      renderInput={(params) => (
        <TextField
          {...params}
          size="small"
          fullWidth
          placeholder={placeHolder ?? '손님 주소를 입력해 주세요'}
          sx={{
            input: {
              '&::placeholder': {
                color: placeHolder === null ? null : '#000000',
              },
            },
          }}
          name="address"
          required={required ?? true}
          onChange={handleInputChange}
        />
      )}
      renderOption={(props, option) => (
        <Box component="li" {...props}>
          {getIcon(option.locationType)}
          <Box sx={{ display: 'flex', flexDirection: 'column', ml: 2 }}>
            <Typography sx={{ fontWeight: 600 }}>
              {option.preferredName !== '' ? `${option.preferredName} : ${option.name}` : option.name}
            </Typography>
            <Typography variant={'caption'}>{option.address}</Typography>
          </Box>
        </Box>
      )}
    />
  );
}
