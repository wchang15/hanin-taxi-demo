import { forwardRef, useEffect, useState } from 'react';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import { TextField } from '@mui/material';
import Typography from '@mui/material/Typography';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import InputAdornment from '@mui/material/InputAdornment';
import Slide from '@mui/material/Slide';
import taxisStore from '../../store/taxisStore';
import userStore from '../../store/userStore';
import hydrationStore from '../../store/hydrationStore';
import apiService from '../apiService/apiService';

const Transition = forwardRef((props, ref) => <Slide direction="up" ref={ref} {...props} />);

export default function TaxiPriceModal({ card, handleClose, setSnackBarMessage }) {
  const { handlePrice } = taxisStore();
  const [price, setPrice] = useState('');

  useEffect(() => {
    if (card) {
      setPrice(card.companyTripPrice);
    }
  }, [card]);

  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  const updatePrice = async () => {
    const res = await apiService().post(`/Company/UpdateTripPrice?tripID=${card.id}&price=${price}`, null, {
      headers: {
        Authorization: `Bearer ${jwtToken}`,
        'Content-Type': 'application/json',
      },
    });
    if (res && res.status === 200) {
      handlePrice(price, card.id);
      setPrice('');
      handleClose();
      setSnackBarMessage(`${card.id}번 택시 가격이 성공적으로 업데이트 되었습니다.`);
    }
  };

  return (
    <div>
      {card && (
        <Dialog
          fullWidth
          maxWidth="sm"
          open={card}
          TransitionComponent={Transition}
          keepMounted
          aria-describedby="alert-dialog-slide-description"
        >
          <DialogTitle>
            <Typography variant={'h5'}>가격 수정하기</Typography>
          </DialogTitle>
          <DialogContent>
            <TextField
              size="small"
              type="number"
              variant="outlined"
              fullWidth
              InputProps={{
                startAdornment: <InputAdornment position="start">$</InputAdornment>,
              }}
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              onFocus={(event) => {
                event.target.select();
              }}
            />
          </DialogContent>
          <DialogActions>
            <Button
              sx={{ color: 'gray' }}
              onClick={() => {
                setPrice('');
                handleClose();
              }}
            >
              닫기
            </Button>
            <Button
              autoFocus
              onClick={() => {
                updatePrice();
              }}
            >
              저장
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </div>
  );
}
