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
} from '@mui/material';
import apiService from '../apiService/apiService';

const Transition = forwardRef((props, ref) => <Slide direction="up" ref={ref} {...props} />);

const reportObject = {
  name: '',
  revenue: 0,
  operations: 0,
  amount: 0,
};

export default function CreateDriverModal({ open, handleClose, update, setUpdate }) {
  const [formData, setFormData] = useState(reportObject);

  useEffect(() => {
    setFormData(reportObject);
  }, [open]);

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    console.log(formData);
    await apiService()
      .post('', {
        name: formData.name,
        revenue: formData.revenue,
        operations: formData.operations,
        amount: formData.amount,
      })
      .then((response) => {
        console.log(response);
        setUpdate(!update);
        handleClose();
      })
      .catch((error) => {
        console.log(error);
      });
  };

  return (
    <div>
      <Dialog open={open} TransitionComponent={Transition} keepMounted maxWidth="md">
        <DialogTitle variant="h3" sx={{ textAlign: 'center', fontWeight: 'bold' }}>{`Create Driver`}</DialogTitle>
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
                <Typography variant="body2" textTransform={'capitalize'}>
                  {key}
                </Typography>
                <TextField
                  fullWidth
                  type={key !== 'name' && 'number'}
                  size="small"
                  disabled={key === 'Id'}
                  id={key}
                  name={key}
                  value={value}
                  onChange={handleInputChange}
                />
              </Box>
            ))}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button variant="outlined" onClick={handleClose} sx={{ marginRight: 1 }}>
            Cancel
          </Button>
          <Button variant="contained" onClick={handleSubmit}>
            Create New Report
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
}
