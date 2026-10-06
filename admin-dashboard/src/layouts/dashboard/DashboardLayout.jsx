import { useState, useEffect } from 'react';
import { Outlet } from 'react-router-dom';
// @mui
import Cookies from 'js-cookie';
import { styled } from '@mui/material/styles';
import { Box, IconButton } from '@mui/material';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
// hooks
import useResponsive from '../../hooks/useResponsive';
//
import Header from './header';
import Nav from './nav';
import apiService from '../../components/apiService/apiService';
import userStore from '../../store/userStore';
// ----------------------------------------------------------------------

const APP_BAR_MOBILE = 64;
const APP_BAR_DESKTOP = 92;

const StyledRoot = styled('div')({
  display: 'flex',
  minHeight: '100%',
  overflow: 'hidden',
});

const Main = styled('div')(({ theme }) => ({
  flexGrow: 1,
  minWidth: 0,
  overflow: 'auto',
  minHeight: '100%',
  paddingTop: APP_BAR_MOBILE + 24,
  paddingBottom: theme.spacing(10),
  [theme.breakpoints.up('lg')]: {
    paddingTop: APP_BAR_DESKTOP + 24,
    paddingLeft: theme.spacing(2),
    paddingRight: theme.spacing(2),
  },
}));

// ----------------------------------------------------------------------

export default function DashboardLayout() {
  const [open, setOpen] = useState(false);
  const [ready, setReady] = useState(false);
  const [collapse, setCollapse] = useState(false);
  const loginUser = userStore((state) => state.setUser);

  const isDesktop = useResponsive('up', 'lg');

  const getCompanyUser = async (rt) => {
    await apiService()
      .post(`/Login/RefreshTokenCompany`, { Token: rt })
      .then((response) => {
        loginUser(response.data);
        setReady(true);
      })
      .catch((error) => {
        window.location.href = '/login';
      });
  };

  useEffect(() => {
    const rt = Cookies.get('refreshToken');
    if (rt) {
      getCompanyUser(rt);
    } else {
      window.location.href = '/login';
    }
  }, []);

  return (
    <StyledRoot>
      {ready && (
        <>
          <Header onOpenNav={() => setOpen(true)} />
          <Box sx={{ display: collapse ? 'none' : 'block' }}>
            <Nav openNav={open} onCloseNav={() => setOpen(false)} onCollapse={() => setCollapse(true)} />
          </Box>
          {isDesktop ? (
            <IconButton onClick={() => setCollapse(false)} sx={{ display: collapse ? 'block' : 'none' }}>
              <NavigateNextIcon />
            </IconButton>
          ) : null}

          <Main>
            <Outlet />
          </Main>
        </>
      )}
    </StyledRoot>
  );
}
