import { forwardRef, useEffect, useState } from 'react';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import { TextField } from '@mui/material';
import Typography from '@mui/material/Typography';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Slide from '@mui/material/Slide';
import taxisStore from '../../store/taxisStore';
import userStore from '../../store/userStore';
import hydrationStore from '../../store/hydrationStore';
import apiService from '../apiService/apiService';

const Transition = forwardRef((props, ref) => <Slide direction="up" ref={ref} {...props} />);

export default function TaxiNoteModal({ card, handleClose, setSnackBarMessage }) {
  const { handleNote } = taxisStore();
  const [note, setNote] = useState('');

  useEffect(() => {
    if (card) {
      setNote(card.notes);
    }
  }, [card]);

  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  const updateNote = async () => {
    const res = await apiService().post(`/Company/UpdateTripNote?tripID=${card.id}&notes=${note}`, null, {
      headers: {
        Authorization: `Bearer ${jwtToken}`,
        'Content-Type': 'application/json',
      },
    });
    if (res && res.status === 200) {
      handleNote(note, card.id);
      setNote('');
      handleClose();
      setSnackBarMessage(`${card.id}번 택시 노트가 성공적으로 업데이트 되었습니다.`);
    }
  };

  const createNote = () => {
    handleNote(note, card.id);
    setNote('');
    handleClose();
    setSnackBarMessage(`${card.id}번 택시 노트가 성공적으로 추가 되었습니다.`);
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
            <Typography variant={'h5'}>노트남기기</Typography>
          </DialogTitle>
          <DialogContent>
            <TextField
              multiline
              rows={10}
              rowsMax={10}
              variant="outlined"
              fullWidth
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
          </DialogContent>
          <DialogActions>
            <Button
              sx={{ color: 'gray' }}
              onClick={() => {
                setNote('');
                handleClose();
              }}
            >
              닫기
            </Button>
            <Button
              autoFocus
              onClick={() => {
                if (typeof card.id === 'string' ) {
                  createNote();
                } else {
                  updateNote();
                }
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
