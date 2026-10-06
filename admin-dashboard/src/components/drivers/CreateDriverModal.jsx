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
  Checkbox,
  Snackbar,
  Alert,
} from '@mui/material';
import apiService from '../apiService/apiService';
import { Sizes, Languages, TaxiColor, TaxiManufacturer } from '../../_mock/user';
import userStore from '../../store/userStore';
import hydrationStore from '../../store/hydrationStore';

const Transition = forwardRef((props, ref) => <Slide direction="up" ref={ref} {...props} />);

const driverObject = {
  driverNumber: null,
  firstName: '',
  lastName: '',
  LoginID: '',
  passwords: '',
  email: '',
  phoneNumber: '',
  color: null,
  make: null,
  size: null,
  model: '',
  licensePlate: '',
  language: null,
};

export default function CreateDriverModal({ setSnackBarMessage, open, handleClose, update, setUpdate }) {
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  useEffect(() => {
    setFormData(driverObject);
  }, [open]);

  const [formData, setFormData] = useState(driverObject);
  const [error, setError] = useState(null);

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
    if (key === 'driverNumber') {
      type = 'number';
    }
    return type;
  };

  const renderSelect = (key) => {
    let select;
    if (key === 'color') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange} required>
          {TaxiColor.map((elem) => {
            return <MenuItem key={elem.value} value={elem.value}>{elem.label}</MenuItem>;
          })}
        </Select>
      );
    } else if (key === 'make') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange} required>
          {TaxiManufacturer.map((elem) => {
            return <MenuItem key={elem.value} value={elem.value}>{elem.label}</MenuItem>;
          })}
        </Select>
      );
    } else if (key === 'size') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange} required>
          {Sizes.map((elem) => {
            return <MenuItem  key={elem.value} value={elem.value}>{elem.label}</MenuItem>;
          })}
        </Select>
      );
    } else if (key === 'language') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange} required>
          {Languages.map((elem) => {
            return <MenuItem key={elem.value} value={elem.value}>{elem.label}</MenuItem>;
          })}
        </Select>
      );
    }

    return select;
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (jwtToken) {
      await apiService()
        .post(
          '/Driver/CreateDriver',
          {
            driverNumber: formData.driverNumber,
            firstName: formData.firstName,
            lastName: formData.lastName,
            account: formData.LoginID,
            passwords: formData.passwords,
            email: formData.email,
            phoneNumber: formData.phoneNumber,
            color: formData.color,
            make: formData.make,
            size: formData.size,
            model: formData.model,
            licensePlate: formData.licensePlate,
            language: formData.language,
          },
          {
            headers: {
              Authorization: `Bearer ${jwtToken}`,
              'Content-Type': 'application/json',
            },
          }
        )
        .then((response) => {
          setSnackBarMessage(`Driver ${response.data} has created`);
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
          <DialogTitle variant="h3" sx={{ textAlign: 'center', fontWeight: 'bold' }}>{`기사님 추가`}</DialogTitle>
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
                    key !== 'email' ? '*' : ''
                  }`}</Typography>
                  {['make', 'color', 'size', 'language'].includes(key) ? (
                    renderSelect(key)
                  ) : (
                    <TextField
                      fullWidth
                      size="small"
                      type={handleType(key)}
                      required={key !== 'email'}
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
              드라이버 추가
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
