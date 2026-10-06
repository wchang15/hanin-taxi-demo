import { Typography, Box, Grid, Paper, Avatar, Tooltip } from '@mui/material';
import IconButton from '@mui/material/IconButton';
import DescriptionIcon from '@mui/icons-material/Description';
import CloseIcon from '@mui/icons-material/Close';
import { TaxiColor, TaxiManufacturer } from '../../_mock/user';

export default function PickUpCard({ card, setOpen, cancelCall, setNote, setPrice }) {
  return (
    <>
      {card && (
        <Grid item xs={12} sm={6} md={4}>
          <Paper elevation={3} sx={{ height: '392px' }}>
            <Box display={'flex'} justifyContent="flex-end">
              <IconButton
                aria-label="close"
                sx={{
                  color: (theme) => theme.palette.grey[500],
                  paddingTop: 1,
                }}
                onClick={() => {
                  cancelCall();
                  // setOpen({
                  //   title: '콜 지우기',
                  //   body: '정말 해당 콜을 지우시겠어요?',
                  //   button: '삭제',
                  //   handleFunction: cancelCall,
                  // });
                }}
              >
                <CloseIcon />
              </IconButton>
            </Box>
            <Box sx={{ paddingLeft: 3, paddingRight: 3 }}>
              <Box display={'flex'} justifyContent={'space-between'} alignItems={'center'}>
                <Box display={'flex'}>
                  <Typography variant="h6" fontWeight={'bold'} sx={{ color: '#424242' }} mr={1}>
                    Driver en route
                  </Typography>
                </Box>
                <Box>
                  <Box display={'flex'} alignItems={'center'}>
                    <IconButton onClick={() => setNote(card)}>
                      <DescriptionIcon color={card.notes !== null && card.notes !== '' ? 'primary' : 'black'} />
                    </IconButton>
                  </Box>
                </Box>
              </Box>
              <Box mt={3} mb={3}>
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
                        {`Driver ${card.assignedDriver.driverNumber}`}
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
                      Pickup
                    </Typography>
                    <Tooltip title={card.startFullAddress} followCursor arrow>
                      <Typography variant="body2" fontWeight={'bold'} sx={{ color: '#424242' }}>
                        {card.addressTitle}
                      </Typography>
                    </Tooltip>
                  </Box>
                </Box>
              </Box>
            </Box>
          </Paper>
        </Grid>
      )}
    </>
  );
}
