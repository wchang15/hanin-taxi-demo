import { useState, useEffect } from 'react';
import { TextField, Autocomplete, Box, Typography } from '@mui/material';
import { debounce, getLocationName } from '../../utils/helper';
import apiService from '../apiService/apiService';

export default function CustomerAutoComplete({ handleSelect, jwtToken, refresh }) {
  const [options, setOptions] = useState([]);
  const [key, setKey] = useState(1);

  useEffect(() => {
    setOptions([]);
    setKey(key + 1);
  }, [refresh]);

  const handleInputChange = debounce(async (event) => {
    const searchTerm = event.target.value;
    if (searchTerm !== '') {
      const response = await apiService().get(`/Company/GetCompanyCustomerPhoneNumber?name=${searchTerm}`, {
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

  return (
    <Autocomplete
      key={key}
      fullWidth
      options={options}
      getOptionLabel={(option) => `${option.customerName}`}
      onChange={(event, value) => {
        handleSelect(value);
      }}
      filterOptions={(x) => x}
      renderInput={(params) => (
        <TextField
          {...params}
          size="small"
          fullWidth
          placeholder={'손님 이름을 입력해 주세요'}
          name="name"
          required={false}
          onChange={handleInputChange}
        />
      )}
      renderOption={(props, option) => (
        <Box component="li" {...props} sx={{ display: 'flex', flexDirection: 'column' }}>
          <Typography>{`${option.customerName} (${option.phoneNumber})`}</Typography>
          <Typography variant={'caption'}>
            {getLocationName(option.locationPreferredName, option.locationName, option.locationAddress)}
          </Typography>
        </Box>
      )}
    />
  );
}
