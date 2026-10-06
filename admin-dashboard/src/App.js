import React, { useState, useEffect } from 'react';
import { BrowserRouter } from 'react-router-dom';
import { HelmetProvider } from 'react-helmet-async';
import Cookies from 'js-cookie';
import { ToastContainer, toast } from 'react-toastify';
import { Snackbar, Backdrop, CircularProgress } from '@mui/material';
import ScrollToTop from './components/scroll-to-top';
import Router from './routes';
import ThemeProvider from './theme';
import { StyledChart } from './components/chart';
import 'react-toastify/dist/ReactToastify.css';
import apiService from './components/apiService/apiService';
import userStore from './store/userStore';
import hydrationStore from './store/hydrationStore';

export default function App() {
  const [isLoading, setIsLoading] = useState(false);
  const [snackBarMessage, setSnackBarMessage] = useState(null);


  return (
    <>
      <HelmetProvider>
        <BrowserRouter>
          <ThemeProvider>
            <ScrollToTop />
            <StyledChart />
            <Router setIsLoading={setIsLoading} setSnackBarMessage={setSnackBarMessage} toast={toast} />
          </ThemeProvider>
        </BrowserRouter>
      </HelmetProvider>
      <Backdrop sx={{ color: '#fff', zIndex: 99999 }} open={isLoading}>
        <CircularProgress color="inherit" />
      </Backdrop>
      <Snackbar
        autoHideDuration={4000}
        sx={{ marginTop: 8 }}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
        open={snackBarMessage}
        onClose={() => {
          setSnackBarMessage(null);
        }}
        message={snackBarMessage}
      />
      <ToastContainer />
    </>
  );
}
