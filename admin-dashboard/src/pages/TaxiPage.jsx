import { Helmet } from 'react-helmet-async';
import * as signalR from '@microsoft/signalr';
import { useEffect, useState } from 'react';
import { styled, alpha } from '@mui/material/styles';
import { Stack, Container, Typography, Box, Button, Chip, Grid, OutlinedInput, InputAdornment } from '@mui/material';
import TimerQueue from 'timer-queue';
import { TaxiCard } from '../components/taxi/TaxiCallCard';
import Iconify from '../components/iconify';
import taxisStore from '../store/taxisStore';
import hydrationStore from '../store/hydrationStore';
import TaxiDalog from '../components/taxi/TaxiDialog';
import TaxiNoteModal from '../components/taxi/TaxiNoteModal';
import TaxiPriceModal from '../components/taxi/TaxiPriceModal';
import apiService from '../components/apiService/apiService';
import userStore from '../store/userStore';
import hubStore from '../store/hubStore';
import { tripConvert } from '../components/taxi/TaxiFunctions';
// hooks
import useResponsive from '../hooks/useResponsive';
import {
  HUBADDRESS,
  MATCH,
  TRIPSTART,
  TRIPCOMPLETE,
  DRIVERCANCEL,
  COMPANYTRIP,
  COMPANYCANCEL,
} from '../utils/constants';

const StyledSearch = styled(OutlinedInput)(({ theme }) => ({
  height: '37px',
  width: '100%',
  transition: theme.transitions.create(['box-shadow', 'width'], {
    easing: theme.transitions.easing.easeInOut,
    duration: theme.transitions.duration.shorter,
  }),
  '&.Mui-focused': {
    boxShadow: theme.customShadows.z8,
  },
  '& fieldset': {
    borderWidth: `1px !important`,
    borderColor: `${alpha(theme.palette.grey[500], 0.32)} !important`,
  },
}));

export default function TaxiPage({ setIsLoading, setSnackBarMessage, toast }) {
  const calls = hydrationStore(taxisStore, (state) => state.calls);

  const { addACall, deleteAllArrival, setCalls, handleCall, handleCompanyCancel, handleUpdate, setCall } = taxisStore();

  const [open, setOpen] = useState(null);
  const [note, setNote] = useState(null);
  const [price, setPrice] = useState(null);

  const [driverNumber, setDriverNumber] = useState('');
  const visibleCalls = calls?.filter(call => !driverNumber ||
    String(call.assignedDriver?.driverNumber ?? '').includes(driverNumber));

  const isDesktop = useResponsive('up', 'lg');

  let hubConnection;
  const tqueue = new TimerQueue({
    interval: 500,
    timeout: 500,
    autoStart: true,
  });

  const company = hydrationStore(userStore, (state) => state.company);
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);
  const isHubConnected = hubStore((state) => state.hubConnection);
  const initHub = hubStore((state) => state.initHub);

  const getTrips = async () => {
    setIsLoading(true);
    try {
      const res = await apiService().get(`/Company/Trips`, {
        headers: {
          Authorization: `Bearer ${jwtToken}`,
          'Content-Type': 'application/json',
        },
      });

      console.log(res.data);
      if (res && res.status === 200) {
        const newCalls = res.data.map((elem) => tripConvert(elem));
        localStorage.setItem('calls', newCalls);
        setCalls(newCalls);
      }
    } catch (err) {
      toast.error(err.message);
    }
    setIsLoading(false);
  };

  const updateTrips = async () => {
    console.log('polling start');
    try {
      if (company && jwtToken) {
        const res = await apiService().get(`/Company/Trips`, {
          headers: {
            Authorization: `Bearer ${jwtToken}`,
            'Content-Type': 'application/json',
          },
        });
        if (res && res.status === 200) {
          console.log('polling', res.data);
          const newCalls = res.data.map((elem) => tripConvert(elem));
          handleUpdate(newCalls);
        }
      }
    } catch (err) {
      toast.error(err.message);
    }
  };

  useEffect(() => {
    const interval = setInterval(updateTrips, 2 * 60 * 1000);
    return () => {
      clearInterval(interval);
    };
  }, [isHubConnected]);

  useEffect(() => {
    if (company && jwtToken) {
      getTrips();
      if (!isHubConnected) {
        try {
          initSignalR();
          initHub(true);
        } catch (err) {
          toast.error(err.message);
        }
      }
    }
  }, [company, isHubConnected]);

  const queueHandleCall = (trip, tripID) => {
    console.log('enqueue', new Date().getTime(), trip);
    tqueue.push(() => {
      console.log('run', new Date().getTime(), trip);
      handleCall(trip, tripID);
    });
  };

  const initSignalR = async () => {
    hubConnection = new signalR.HubConnectionBuilder()
      .withUrl(HUBADDRESS, {
        skipNegotiation: true,
        timeout: 600000,
        transport: signalR.HttpTransportType.WebSockets,
      })

      // .withAutomaticReconnect([10000, 1000, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]) // reconnect for 3 minutes
      // Try to reconnect every 10 seconds for 60 seconds; If fail -> fail
      .withAutomaticReconnect({
        nextRetryDelayInMilliseconds: (retryContext) => {
          if (retryContext.elapsedMilliseconds < 60000) {
            return 1000;
          }
          return null;
        },
      })
      .build();

    hubConnection.keepAliveIntervalInMilliseconds = 1000 * 60 * 5;
    hubConnection.serverTimeoutInMilliseconds = 1000 * 60 * 10;

    // if the connection fail -> start it again
    hubConnection.onclose(({ error }) => {
      console.log('onClose Hub');
      initHub(false);
      hubConnection.start().then(() => addToGroup());
    });

    hubConnection.on(COMPANYTRIP, (stage, trip) => {
      console.log(COMPANYTRIP, trip);
      const updateTrip = tripConvert(trip);
      tqueue.push(() => {
        setCall(updateTrip);
      });
    });

    hubConnection.on(COMPANYCANCEL, (stage, id) => {
      console.log(COMPANYCANCEL, id);
      tqueue.push(() => {
        handleCompanyCancel(id);
      });
    });

    hubConnection.on(MATCH, (stage, trip) => {
      const updateTrip = tripConvert(trip);
      queueHandleCall(updateTrip, trip.tripID);
    });

    hubConnection.on(TRIPSTART, (stage, trip) => {
      console.log(TRIPSTART, stage, trip);
      const updateTrip = tripConvert(trip);
      if (trip.companyTripPrice === 0) {
        toast.error(`Call with ID ${trip.tripID} doesn't have a price.`, { autoClose: false });
      }
      queueHandleCall(updateTrip, trip.tripID);
    });

    hubConnection.on(TRIPCOMPLETE, (stage, trip) => {
      console.log(TRIPCOMPLETE, stage, trip);
      const updateTrip = tripConvert(trip);
      queueHandleCall(updateTrip, trip.tripID);
    });

    hubConnection.on(DRIVERCANCEL, (stage, trip) => {
      console.log(DRIVERCANCEL, stage, trip);
      const updateTrip = tripConvert(trip);
      queueHandleCall(updateTrip, trip.tripID);
    });

    hubConnection.onreconnected(({ connectionId }) => {
      console.log('Hub Reconnected');
      addToGroup();
    });

    hubConnection.onreconnecting(({ error }) => {
      console.log('hub reconnecting $error');
    });

    await hubConnection.start();
    addToGroup();
  };

  const addToGroup = () => {
    console.log(`company${company.companyID}`);
    hubConnection.invoke('AddToGroup', `company${company.companyID}`);
  };

  const DeleteAllArrival = async () => {
    await apiService()
      .post(`/Company/DeleteAllArrival`, null, {
        headers: {
          Authorization: `Bearer ${jwtToken}`,
          'Content-Type': 'application/json',
        },
      })
      .then((response) => {
        deleteAllArrival();
      })
      .catch((error) => {
        console.log(error);
      });
  };

  return (
    <>
      <Helmet>
        <title> Taxi | Hanin Taxi </title>
      </Helmet>
      <Container maxWidth={false}>
        <Stack direction={{ xs: 'column', md: 'row' }} alignItems={{ xs: 'stretch', md: 'center' }} justifyContent="space-between" gap={2} mb={3}>
          <Box>
            <Typography variant="h4" gutterBottom>
              Live Dispatch
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Monitor active requests and driver assignments in real time.
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', alignItems: 'center', flexWrap: { xs: 'wrap', md: 'nowrap' }, gap: 1 }}>
            {!isDesktop ? (
              <StyledSearch
                size="small"
                type="number"
                placeholder="Search by driver number..."
                inputProps={{ 'aria-label': 'Search by driver number' }}
                value={driverNumber}
                onChange={(e) => {
                  setDriverNumber(e.target.value);
                }}
                startAdornment={
                  <InputAdornment position="start">
                    <Iconify icon="eva:search-fill" sx={{ color: 'text.disabled', width: 20, height: 20 }} />
                  </InputAdornment>
                }
              />
            ) : null}
            <Button
              variant="outlined"
              sx={{ flex: { xs: 1, md: 'initial' }, whiteSpace: 'nowrap' }}
              onClick={() => {
                setOpen({
                  title: '완료된 콜 전체 지우기',
                  body: '정말 완료된 전체 콜을 지우시겠어요?',
                  button: '삭제',
                  handleFunction: DeleteAllArrival,
                });
              }}
            >
              Clear completed
            </Button>

            <Button
              variant="contained"
              sx={{ color: 'white', flex: { xs: 1, md: 'initial' }, whiteSpace: 'nowrap' }}
              onClick={() => {
                // if (calls.filter(call => call.stage === 1).length > 5) {
                //   setSnackBarMessage('Call 카드 완료후 추가 하십시오');
                // } else {
                addACall();
                // }
              }}
            >
              New call
            </Button>
          </Box>
        </Stack>
        <Stack direction="row" gap={1} mb={4} flexWrap="wrap">
          <Chip label={`${calls?.length || 0} active trips`} color="primary" variant="outlined" />
          <Chip label={`${calls?.filter((call) => call.stage === 4).length || 0} driver en route`} variant="outlined" />
          <Chip label={`${calls?.filter((call) => call.stage === 3).length || 0} matching`} variant="outlined" />
        </Stack>
        {calls && (
          <Box>
            <Grid container spacing={3}>
              {visibleCalls.map((elem) => {
                return <TaxiCard key={elem.id} call={elem} calls={calls} setOpen={setOpen} setNote={setNote} setPrice={setPrice} />;
              })}
            </Grid>
          </Box>
        )}
      </Container>
      <TaxiDalog open={open} handleClose={() => setOpen(null)} />
      <TaxiNoteModal card={note} handleClose={() => setNote(null)} setSnackBarMessage={setSnackBarMessage} />
      <TaxiPriceModal card={price} handleClose={() => setPrice(null)} setSnackBarMessage={setSnackBarMessage} />
    </>
  );
}
