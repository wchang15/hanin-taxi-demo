import { useState } from 'react';
import { alpha } from '@mui/material/styles';
import Cookies from 'js-cookie';
import { Box, Divider, Typography, MenuItem, Avatar, IconButton, Popover } from '@mui/material';
import apiService from '../../../components/apiService/apiService';
import userStore from '../../../store/userStore';
import hydrationStore from '../../../store/hydrationStore';

export default function AccountPopover() {
  const [open, setOpen] = useState(null);

  const handleOpen = (event) => {
    setOpen(event.currentTarget);
  };

  const handleClose = () => {
    setOpen(null);
  };

  const company = hydrationStore(userStore, (state) => state.company);

  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  const reset = userStore((state) => state.reset);

  const handleLogout = async () => {
    try {
      if (jwtToken) {
        await apiService().get(`/Login/Logout`, {
          timeout: 5000,
          headers: {
            Authorization: `Bearer ${jwtToken}`,
            'Content-Type': 'application/json',
          },
        });
      }
    } catch {
      // Local sign-out must work even if the server cannot revoke the session.
    } finally {
      reset();
      window.location.href = '/login';
    }
  };

  return (
    <>
      {company && (
        <>
          <IconButton
            aria-label="Account menu"
            onClick={handleOpen}
            sx={{
              p: 0,
              ...(open && {
                '&:before': {
                  zIndex: 1,
                  content: "''",
                  width: '100%',
                  height: '100%',
                  borderRadius: '50%',
                  position: 'absolute',
                  bgcolor: (theme) => alpha(theme.palette.grey[900], 0.8),
                },
              }),
            }}
          >
            <Avatar sx={{ bgcolor: 'orange', textTransform: 'uppercase' }}> {company.name.charAt(0)}</Avatar>
          </IconButton>

          <Popover
            open={Boolean(open)}
            anchorEl={open}
            onClose={handleClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: 'right' }}
            PaperProps={{
              sx: {
                p: 0,
                mt: 1.5,
                ml: 0.75,
                width: 180,
                '& .MuiMenuItem-root': {
                  typography: 'body2',
                  borderRadius: 0.75,
                },
              },
            }}
          >
            <Box sx={{ my: 1.5, px: 2.5 }}>
              <Typography variant="subtitle2" noWrap>
                {company.contactName}
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary' }} noWrap>
                {company.name}
              </Typography>
            </Box>
            <Divider sx={{ borderStyle: 'dashed' }} />
            <Divider sx={{ borderStyle: 'dashed' }} />
            <MenuItem
              onClick={() => {
                handleLogout();
              }}
              sx={{ m: 1 }}
            >
              로그아웃
            </MenuItem>
          </Popover>
        </>
      )}
    </>
  );
}
