import { Typography, Box, Grid, Paper, Avatar, Tooltip, IconButton } from '@mui/material';
import DescriptionIcon from '@mui/icons-material/Description';
import PaidIcon from '@mui/icons-material/Paid';
import { TaxiColor, TaxiManufacturer } from '../../_mock/user';

export default function RidingCard({ card, setNote, setPrice }) {
  return (
    <Grid item xs={12} sm={6} md={4}>
      <Paper
        elevation={3}
        sx={{
          height: '392px',
          padding: 3,
          border:
            card.companyTripPrice === null ||
            card.companyTripPrice === '' ||
            (card.companyTripPrice === 0 && '2px solid #FF5630'),
        }}
      >
        <Box display={'flex'} alignItems={'center'} justifyContent={'space-between'} flexWrap={'wrap'}>
          <Box display={'flex'}>
            {/* <Box
              sx={{
                backgroundColor: '#9DA2AA',
                width: '26px',
                color: '#ffffff',
                display: 'flex',
                justifyContent: 'center',
                borderRadius: '50%',
              }}
              mr={1}
            >
              <Typography variant="h6">1</Typography>
            </Box> */}
            <Typography variant="h6" fontWeight={'bold'} sx={{ color: '#424242' }} mr={1}>
              운행중
            </Typography>
          </Box>
          <Box display={'flex'} flexWrap={'wrap'}>
            <Box display={'flex'} alignItems={'center'}>
              <IconButton sx={{ cursor: 'pointer' }} onClick={() => setPrice(card)}>
                <PaidIcon
                  color={
                    card.companyTripPrice !== null && card.companyTripPrice !== '' && card.companyTripPrice !== 0
                      ? 'primary'
                      : 'black'
                  }
                />
              </IconButton>
            </Box>
            <Box display={'flex'} alignItems={'center'}>
              <IconButton sx={{ cursor: 'pointer' }} onClick={() => setNote(card)}>
                <DescriptionIcon color={card.notes !== null && card.notes !== '' ? 'primary' : 'black'} />
              </IconButton>
            </Box>
          </Box>
        </Box>
        <Box mt={1} mb={3}>
          <Box
            sx={{ backgroundColor: '#FBFAFA', borderRadius: 3 }}
            height="276px"
            display={'flex'}
            alignItems="center"
            flexDirection="column"
            justifyContent={'center'}
          >
            <Box mb={2}>
              <Avatar>J</Avatar>
            </Box>
            <Box sx={{ textAlign: 'center' }} mb={3}>
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
      </Paper>
    </Grid>
  );
}
