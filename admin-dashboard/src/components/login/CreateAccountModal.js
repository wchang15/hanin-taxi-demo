import { forwardRef } from 'react';
import {
  Slide,
  Dialog,
  Button,
  DialogTitle,
  DialogActions,
  DialogContent,
  DialogContentText,
  Box,
} from '@mui/material';

const Transition = forwardRef((props, ref) => <Slide direction="up" ref={ref} {...props} />);

export default function CreateAccountModal({ open, handleClose }) {
  return (
    <div>
      <Dialog open={open} TransitionComponent={Transition} keepMounted maxWidth="sm" onClose={handleClose}>
        <DialogTitle
          variant="h5"
          sx={{ textAlign: 'center', fontWeight: 'bold' }}
        >{`Create Your Hanin Taxi Account for Convenient Dashboard Access`}</DialogTitle>

        <DialogContent>
          <DialogContentText variant="h6" sx={{ textAlign: 'center' }}>
            To access the Hanin Taxi dashboard and manage your transportation needs, please contact our internal tech
            team to create your Hanin Taxi account.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Box sx={{ display: 'flex', justifyContent: 'center', width: '100%' }} mt={2} mb={2}>
            <Button variant="contained" onClick={handleClose} sx={{ width: '200px' }}>
              Exit
            </Button>
          </Box>
        </DialogActions>
      </Dialog>
    </div>
  );
}
