import { Typography, Box, Grid, Paper, Tooltip } from '@mui/material';
import IconButton from '@mui/material/IconButton';
import CloseIcon from '@mui/icons-material/Close';
import LoadingBouncingDot from '../animation/BouncingDots';

export default function MatchingCard({ card, setOpen, cancelCall }) {
  return (
    <Grid item xs={12} sm={6} md={4}>
      <Paper elevation={3} sx={{ height: '392px' }}>
        <Box display={'flex'} justifyContent="flex-end">
          <IconButton
            aria-label="close"
            sx={{
              marginTop: 1,
              color: (theme) => theme.palette.grey[500],
            }}
            onClick={() => {
              setOpen({
                title: '매칭 취소',
                body: '정말 매칭을 취소하시겠어요?',
                button: '매칭취소',
                handleFunction: () => cancelCall(),
              });
            }}
          >
            <CloseIcon />
          </IconButton>
        </Box>
        <Box>
          <Box display={'flex'} flexDirection="column" justifyContent="center" alignItems={'center'} mt={10} mb={9}>
            <LoadingBouncingDot />
            <Typography variant="h5" mt={3}>
              Matching driver...
            </Typography>
          </Box>
        </Box>

        <Box mt={3} mb={3}>
          <Box
            sx={{ backgroundColor: '#FBFAFA', borderRadius: 3 }}
            height="88px"
            display={'flex'}
            alignItems="center"
            flexDirection="column"
            justifyContent={'center'}
            mr={2}
            ml={2}
          >
            <Typography variant="h6" sx={{ color: '#9398A1' }}>
              Pickup
            </Typography>
            <Tooltip title={card.startFullAddress} followCursor arrow>
              <Typography variant="h6" sx={{ color: '#424242', width : "100%", textAlign: "center", textOverflow: "ellipsis", whiteSpace: "nowrap" ,padding: "0px 10px" }} textOverflow={'ellipsis'} noWrap >
                {card.addressTitle}
              </Typography>
            </Tooltip>
          </Box>
        </Box>
      </Paper>
    </Grid>
  );
}
