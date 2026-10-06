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

export default function EditDriverModal({ setSnackBarMessage, open, handleClose, row, update, setUpdate }) {
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  useEffect(() => {
    if (row) {
      const driverData = {
        id: row.id,
        driverNumber: row.driverNumber,
        loginID: row.account,
        firstName: row.firstName,
        lastName: row.lastName,
        email: row.email,
        phoneNumber: row.phoneNumber,
        color: row.color,
        make: row.make,
        size: row.size,
        model: row.model,
        licensePlate: row.licensePlate,
        language: row.language,
      };
      setFormData(driverData);
    }
  }, [open]);

  const [formData, setFormData] = useState(row);
  const [error, setError] = useState(null);

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    console.log(event.target.type);
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

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (jwtToken) {
      await apiService()
        .post(
          '/Driver/EditDriver',
          {
            id: formData.id,
            driverNumber: formData.driverNumber,
            firstName: formData.firstName,
            lastName: formData.lastName,
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
          console.log(response);
          setSnackBarMessage(`Driver ${response.data.firstName} has been edited`);
          setUpdate(!update);
          handleClose();
        })
        .catch((error) => {
          setError(error.response.data);
        });
    }
  };

  const renderSelect = (key) => {
    let select;
    if (key === 'color') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange}>
          {TaxiColor.map((elem) => {
            return (
              <MenuItem key={elem.value} value={elem.value}>
                {elem.label}
              </MenuItem>
            );
          })}
        </Select>
      );
    } else if (key === 'make') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange}>
          {TaxiManufacturer.map((elem) => {
            return (
              <MenuItem key={elem.value} value={elem.value}>
                {elem.label}
              </MenuItem>
            );
          })}
        </Select>
      );
    } else if (key === 'size') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange}>
          {Sizes.map((elem) => {
            return (
              <MenuItem key={elem.value} value={elem.value}>
                {elem.label}
              </MenuItem>
            );
          })}
        </Select>
      );
    } else if (key === 'language') {
      select = (
        <Select size="small" fullWidth id={key} name={key} value={formData[key]} onChange={handleInputChange}>
          {Languages.map((elem) => {
            return (
              <MenuItem key={elem.value} value={elem.value}>
                {elem.label}
              </MenuItem>
            );
          })}
        </Select>
      );
    }

    return select;
  };

  return (
    <div>
      {formData && (
        <Dialog open={open} TransitionComponent={Transition} keepMounted maxWidth="md">
          <form onSubmit={handleSubmit}>
            <DialogTitle
              variant="h3"
              sx={{ textAlign: 'center', fontWeight: 'bold' }}
            >{`기사님 정보 수정`}</DialogTitle>
            <DialogContent sx={{ overflowX: 'hidden' }}>
              <Stack
                sx={{
                  width: '100%',
                  minWidth: { xs: '300px', sm: '400px', md: '450px' },
                  gap: '0.5rem',
                }}
              >
                {Object.entries(formData).map(([key, value]) => (
                  <Box key={key} sx={{ display: key === 'id' && 'none' }}>
                    <Typography variant="body2" textTransform={'capitalize'}>
                      {key}
                    </Typography>
                    {['make', 'color', 'size', 'language'].includes(key) ? (
                      renderSelect(key)
                    ) : (
                      <TextField
                        fullWidth
                        required={key !== 'email'}
                        size="small"
                        type={handleType(key)}
                        disabled={key === 'id' || key === 'loginID'}
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
                Cancel
              </Button>
              <Button variant="contained" type="submit" sx={{ color: 'white' }}>
                Edit New Driver
              </Button>
            </DialogActions>
          </form>
        </Dialog>
      )}
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
