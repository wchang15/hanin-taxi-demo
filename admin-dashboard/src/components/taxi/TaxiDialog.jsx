import { forwardRef } from 'react';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import Typography from '@mui/material/Typography';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import Slide from '@mui/material/Slide';

const Transition = forwardRef((props, ref) => <Slide direction="up" ref={ref} {...props} />);

export default function TaxiDialog({ open, handleClose }) {
  return (
    <div>
      {open && (
        <Dialog
          fullWidth
          maxWidth="sm"
          open={open}
          TransitionComponent={Transition}
          keepMounted
          onClose={handleClose}
          aria-describedby="alert-dialog-slide-description"
        >
          <DialogTitle>
            <Typography variant={'h5'}>{open.title}</Typography>
          </DialogTitle>
          <DialogContent>
            <DialogContentText id="alert-dialog-slide-description">
              <Typography variant={'subtitle2'}>{open.body}</Typography>
            </DialogContentText>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleClose} sx={{ color: 'gray' }}>
              닫기
            </Button>
            <Button
              onClick={() => {
                open.handleFunction();
                handleClose();
              }}
            >
              {open.button}
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </div>
  );
}
