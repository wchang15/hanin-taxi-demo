import { Typography, Box, Button, Grid, Paper, Avatar, Tooltip } from '@mui/material';
import { TaxiColor, TaxiManufacturer } from '../../_mock/user';

export default function ArrivedCard({ card, cancelCall }) {
  return (
    <Grid item xs={12} sm={6} md={4}>
      <Paper elevation={3} sx={{ height: '392px', padding: 3 }}>
        <Box display={'flex'} justifyContent="center">
          <Typography variant="h6" fontWeight={'bold'} sx={{ color: '#424242' }} mr={1}>
            도착
          </Typography>
        </Box>
        <Box mt={2} mb={2}>
          <Box
            sx={{ backgroundColor: '#FBFAFA', borderRadius: 3 }}
            height="250px"
            display={'flex'}
            alignItems="center"
            flexDirection="column"
            justifyContent={'center'}
          >
            <Box mb={1} mt={1}>
              <Avatar>J</Avatar>
            </Box>
            <Box sx={{ textAlign: 'center' }} mb={2}>
              <Box display={'flex'} justifyContent="center">
                <Typography variant="body2" fontWeight={'bold'} sx={{ color: '#424242' }}>
                  {`${card.assignedDriver.driverNumber}번 기사님 `}
                </Typography>
                {/* <Typography variant="subtitle2" sx={{ color: '#9398A1' }} ml={1}>
                  {card.assignedDriver.companyName}
                </Typography> */}
              </Box>
              <Typography variant="body2" fontWeight={'bold'} sx={{ color: '#424242' }}>
                {`${card.assignedDriver.carplate} | ${
                  TaxiManufacturer.find((item) => item.value === card.assignedDriver.make).label
                } ${TaxiColor.find((item) => item.value === card.assignedDriver.color).label}`}
              </Typography>
              <Typography variant="body2" fontWeight={'bold'} sx={{ color: '#424242' }}>
                {card.assignedDriver.phonenumber}
              </Typography>
            </Box>
            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="subtitle2" sx={{ color: '#9398A1' }}>
                손님 픽업 주소
              </Typography>
              <Tooltip title={card.startFullAddress} followCursor arrow>
                <Typography variant="body2" fontWeight={'bold'} sx={{ color: '#424242' }}>
                  {card.addressTitle}
                </Typography>
              </Tooltip>
            </Box>
            <Box sx={{ textAlign: 'center' }} mt={1}>
              <Typography variant="subtitle2" sx={{ color: '#9398A1' }}>
                손님 드랍오프 주소
              </Typography>
              <Tooltip title={card.endFullAddress} followCursor arrow>
                <Typography variant="body2" fontWeight={'bold'} sx={{ color: '#424242' }}>
                  {card.dropOffaddress}
                </Typography>
              </Tooltip>
            </Box>
          </Box>
        </Box>
        <Box mt={1}>
          <Button variant="contained" fullWidth sx={{ color: 'white' }} onClick={cancelCall}>
            도착완료
          </Button>
        </Box>
      </Paper>
    </Grid>
  );
}
