import { forwardRef, useEffect, useState } from 'react';
import {
  Slide,
  Dialog,
  Button,
  DialogTitle,
  DialogActions,
  DialogContent,
  Box,
  Typography,
  TextField,
  Stack,
  Select,
  MenuItem,
  Snackbar,
  Alert,
} from '@mui/material';
import { Sizes, Languages, TaxiColor, TaxiManufacturer } from '../../_mock/user';
import userStore from '../../store/userStore';
import hydrationStore from '../../store/hydrationStore';
import AddressAutoComplete from '../taxi/AddressAutoComplete';
import apiService from '../apiService/apiService';

const Transition = forwardRef((props, ref) => <Slide direction="up" ref={ref} {...props} />);

const customerObject = {
  customerName: '',
  phoneNumber: '',
  location: '',
  excludedDrivers: '',
};

export default function CreateCustomerModal({ setSnackBarMessage, open, handleClose, update, setUpdate }) {
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  const [formData, setFormData] = useState(customerObject);
  const [error, setError] = useState(null);
  const [address, setAddress] = useState(null);
  const [refresh, setRefresh] = useState(false);

  useEffect(() => {
    setFormData(customerObject);
    setAddress(null);
    setRefresh(!refresh);
  }, [open]);

  const handleAddressSelect = (selected) => {
    if (selected != null) {
      setAddress(selected);
    } else {
      setAddress(null);
    }
  };

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    if (name === 'phoneNumber') {
      const phoneRegex = /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/;
      const number = value.replace(phoneRegex, '$1-$2-$3');
      setFormData((prevFormData) => ({ ...prevFormData, phoneNumber: number }));
    } else {
      setFormData((prevFormData) => ({ ...prevFormData, [name]: value }));
    }
  };

  const handleType = (key) => {
    let type = 'text';
    if (key === 'email') {
      type = 'email';
    }
    return type;
  };

 

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (jwtToken) {
      const model = {
        customerName: formData.customerName,
        phoneNumber: formData.phoneNumber,
        locationName: '',
        locationAddress: '',
        locationLatitude: 0,
        locationLongitude: 0,
        locationtype: 0,
      };
      if (address !== null) {
        model.locationName = address.name;
        model.locationAddress = address.address;
        model.locationLatitude = address.latitude;
        model.locationLongitude = address.longitude;
        model.locationtype = address.locationType;
      }
      await apiService()
        .post('/Company/AddCompanyCustomerPhoneNumber', model, {
          headers: {
            Authorization: `Bearer ${jwtToken}`,
            'Content-Type': 'application/json',
          },
        })
        .then((response) => {
          setSnackBarMessage(`Customer ${response.data} has created`);
          setUpdate(!update);
          handleClose();
        })
        .catch((error) => {
          setError(error.response.data);
        });
    }
  };
  return (
    <div>
      <Dialog open={open} TransitionComponent={Transition} keepMounted maxWidth="md">
        <form onSubmit={handleSubmit}>
          <DialogTitle variant="h3" sx={{ textAlign: 'center', fontWeight: 'bold' }}>{`손님 추가`}</DialogTitle>
          <DialogContent>
            <Stack
              sx={{
                width: '100%',
                minWidth: { xs: '300px', sm: '400px', md: '450px' },
                gap: '0.5rem',
                overflowX: 'hidden',
              }}
            >
              {Object.entries(formData).map(([key, value]) => (
                <Box key={key}>
                  <Typography variant="body2" textTransform={'capitalize'}>{`${key}${
                    !['excludedDrivers', 'location'].includes(key) ? '*' : ''
                  }`}</Typography>
                  {key === 'location' ? (
                    <AddressAutoComplete
                      handleSelect={handleAddressSelect}
                      jwtToken={jwtToken}
                      refresh={refresh}
                      required={false}
                    />
                  ) : (
                    <TextField
                      fullWidth
                      size="small"
                      type={handleType(key)}
                      required={!['excludedDrivers', 'location'].includes(key)}
                      id={key}
                      name={key}
                      value={value}
                      onChange={handleInputChange}
                    />
                  )}
                </Box>
              ))}
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button variant="outlined" onClick={handleClose} sx={{ marginRight: 1 }}>
              취소
            </Button>
            <Button variant="contained" type="submit" sx={{ color: 'white' }}>
              손님 추가
            </Button>
          </DialogActions>
        </form>
      </Dialog>
      <Snackbar
        autoHideDuration={4000}
        sx={{ marginTop: 8 }}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
        open={error}
        onClose={() => {
          setError(null);
        }}
      >
        <Alert severity="error">{error}</Alert>
      </Snackbar>
    </div>
  );
}
