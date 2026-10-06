import { Helmet } from 'react-helmet-async';
import { Container, Typography, Box } from '@mui/material';
import { styled, alpha } from '@mui/material/styles';
import { bgGradient } from '../utils/cssStyles';
import userStore from '../store/userStore';
import hydrationStore from '../store/hydrationStore';

export const StyledSectionBg = styled('div')(({ theme }) => ({
  ...bgGradient({
    color: alpha(theme.palette.background.default, theme.palette.mode === 'light' ? 0.9 : 0.94),
    imgUrl: '/background/overlay_2.jpg',
  }),
  top: 0,
  left: 0,
  zIndex: -1,
  width: '100%',
  height: '100%',
  position: 'absolute',
  transform: 'scaleX(-1)',
}));

export default function DashboardAppPage() {
  const company = hydrationStore(userStore, (state) => state.company);
  return (
    <>
      <Helmet>
        <title> Dashboard | Hanin Taxi </title>
      </Helmet>
      <Container maxWidth="xl">
        <Box
          sx={{
            height: 'calc(100vh - 197px)',
          }}
          display="flex"
          flexDirection={'column'}
          justifyContent={'center'}
          alignItems={'center'}
        >
          <Typography variant="h3" sx={{ maxWidth: 480, textAlign: 'center' }}>
            안녕하세요
          </Typography>
          {company && (
            <Typography variant="h3" sx={{ mb: 8, maxWidth: 480, textAlign: 'center' }}>
              {company.contactName}
            </Typography>
          )}
          <Box component="img" alt={'logo'} src={'/logo/Logo_single.png'} sx={{ maxWidth: 186 }} />
        </Box>
        <StyledSectionBg />
      </Container>
    </>
  );
}
