import { useState } from 'react';
import {
  Typography,
  Box,
  Grid,
  Paper,
  TextField,
  MenuItem,
  Select,
  FormControl,
  FormControlLabel,
  Switch,
  IconButton,
} from '@mui/material';
import LoadingButton from '@mui/lab/LoadingButton';
import DescriptionIcon from '@mui/icons-material/Description';
import apiService from '../apiService/apiService';
import AddressAutoComplete from './AddressAutoComplete';
import CustomerAutoComplete from './CustomerAutoComplete';
import { EnumLocationType } from '../../_mock/taxi';
import { getLocationName } from '../../utils/helper';

export default function CallingCard({
  card,
  handleCall,
  jwtToken,
  setNote,
  handleAddress,
  handleOption,
  handlePhoneNumber,
  initialAddress,
}) {
  const [error, setError] = useState(null);
  const [checked, setChecked] = useState(false);
  const [addressPlaceHolder, setAddressPlaceHolder] = useState(null);

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (card.address === '' || card.addressTitle === '' || card.latitude === '' || card.longitude === '') {
      setError('Please select the address from the drop down');
    } else if (card.option === 0) {
      setError('Please select option');
    } else {
      await apiService()
        .post(
          `/Company/NewTrip`,
          {
            PickupName: card.addressTitle,
            PickupAddress: card.address,
            PickupLatitude: card.latitude,
            PickupLongitude: card.longitude,
            Notes: card.notes,
            LocationType: card.locationType,
            CustomerPhoneNumber: card.phone,
            EnumTripType: card.option,
            CalledTaxiSize: checked ? 2 : 1,
          },
          {
            headers: {
              Authorization: `Bearer ${jwtToken}`,
              'Content-Type': 'application/json',
            },
          }
        )
        .then((response) => {
          const draftId = card.id;
          const tripId = response.data.tripID;
          if (tripId) {
            const newCard = { ...card, stage: 3, id: tripId };
            handleCall(newCard, draftId);
          }
        })
        .catch((error) => {
          console.log(error);
        });
    }
  };

  const handleSelect = (selected) => {
    if (selected != null) {
      handleAddress(selected, card.id);
    } else {
      initialAddress(card.id);
    }
  };

  const handleCustomerSelect = (selected) => {
    if (selected.locationName !== '' && card.addressTitle === '') {
      handleAddress(
        {
          address: selected.locationAddress,
          name: selected.locationName,
          latitude: 0,
          longitude: 0,
          locationType: EnumLocationType.OTHER,
        },
        card.id
      );
      setAddressPlaceHolder(
        getLocationName(selected.locationPreferredName, selected.locationName, selected.locationAddress)
      );
    }
    handlePhoneNumber(selected.phoneNumber, card.id);
  };

  const onhandlePhoneNumber = (event) => {
    const { value } = event.target;
    const phoneRegex = /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/;
    const number = value.replace(phoneRegex, '$1-$2-$3');
    handlePhoneNumber(number, card.id);
  };

  return (
    <Grid item xs={12} sm={6} md={4}>
      <form onSubmit={handleSubmit}>
        <Paper elevation={3} sx={{ height: '392px', padding: 3 }}>
          <Box display={'flex'} sx={{ flexWrap: 'nowrap' }} justifyContent={'space-between'} alignItems={'center'}>
            <Typography variant="h6">New call</Typography>
            <Box display={'flex'} sx={{ flexWrap: 'nowrap' }} alignItems={'center'}>
              <FormControl>
                <FormControlLabel
                  control={<Switch name="checked" color="primary" onChange={(e) => setChecked(e.target.checked)} />}
                  sx={{ display: 'flex', marginRight: '-12px' }}
                />
              </FormControl>
              <Box display={'flex'} alignItems={'center'}>
                <IconButton onClick={() => setNote(card)}>
                  <DescriptionIcon color={card.notes !== null && card.notes !== '' ? 'primary' : 'black'} />
                </IconButton>
              </Box>
            </Box>
          </Box>
          <Box mt={1} mb={3} display="flex" justifyContent={'center'} flexDirection="column">
            <AddressAutoComplete
              handleSelect={handleSelect}
              jwtToken={jwtToken}
              placeHolder={addressPlaceHolder}
              required={false}
            />
            <Select
              sx={{ marginY: 2 }}
              size="small"
              defaultValue={2}
              name="option"
              onChange={(e) => {
                handleOption(e.target.value, card.id);
              }}
              required
            >
              <MenuItem value={0} disabled defaultChecked>
                <em>Select payment type</em>
              </MenuItem>
              <MenuItem value={2}>Cash</MenuItem>
              <MenuItem value={3}>Voucher</MenuItem>
              <MenuItem value={4}>Designated driver</MenuItem>
              {/* <MenuItem value={5}>대리기사 2</MenuItem> */}
            </Select>
            <TextField
              fullWidth
              size="small"
              value={card.phone}
              placeholder="Customer phone (optional)"
              name="phone"
              sx={{ mb: 2 }}
              onChange={(e) => {
                onhandlePhoneNumber(e);
              }}
            />
            <Box>
              <CustomerAutoComplete handleSelect={handleCustomerSelect} jwtToken={jwtToken} />
            </Box>
          </Box>
          {error && (
            <Typography variant="body2" color="error" textAlign={'center'}>
              {error}
            </Typography>
          )}
          <Box mt={1} display="flex" justifyContent={'space-between'}>
            <LoadingButton variant="contained" fullWidth sx={{ mr: 1, padding: 1, color: 'white' }} type="submit">
              Hanin fleet
            </LoadingButton>
            <LoadingButton
              variant="contained"
              color="black"
              fullWidth
              sx={{ ml: 1, padding: 1, color: 'white' }}
              type="submit"
            >
              All fleets
            </LoadingButton>
          </Box>
        </Paper>
      </form>
    </Grid>
  );
}
