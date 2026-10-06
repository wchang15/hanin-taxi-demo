import { Helmet } from 'react-helmet-async';
import { styled, alpha } from '@mui/material/styles';
import * as Yup from 'yup';
import { yupResolver } from '@hookform/resolvers/yup';
import { useForm, FormProvider, Controller } from 'react-hook-form';
import { Link, Typography, Stack, Box, Alert, TextField, Grid } from '@mui/material';
import LoadingButton from '@mui/lab/LoadingButton';
import Logo from '../components/logo';
import { bgGradient } from '../utils/cssStyles';

export const StyledRoot = styled('main')(() => ({
  height: '100vh',
  display: 'flex',
  position: 'relative',
}));

export const StyledSection = styled('div')(({ theme }) => ({
  flexGrow: 1,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  flexDirection: 'column',
}));

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

export default function ForgotPasswordPage() {
  const defaultValues = {
    email: '',
  };

  const ForgotPasswordSchema = Yup.object().shape({
    email: Yup.string().required('Email is required').email('Email must be a valid email address'),
  });

  const methods = useForm({
    resolver: yupResolver(ForgotPasswordSchema),
    defaultValues,
  });

  const {
    reset,
    setError,
    handleSubmit,
    control,
    formState: { errors, isSubmitting, isSubmitSuccessful },
  } = methods;

  const onSubmit = async (data) => {
    console.log(data);
  };

  return (
    <>
      <Helmet>
        <title> Forgot Password | Hanin Taxi </title>
      </Helmet>
      <StyledRoot>
        <Logo
          sx={{
            zIndex: 9,
            position: 'absolute',
            mt: { xs: 1.5, md: 5 },
            ml: { xs: 2, md: 5 },
          }}
        />
        <StyledSection>
          <Grid
            container
            sx={{
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              height: '100vh',
              position: 'relative',
            }}
          >
            <Grid
              item
              xs={10}
              sm={8}
              md={6}
              lg={4}
              xl={3}
              sx={{
                display: 'flex',
                flexDirection: 'column',
              }}
            >
              <FormProvider {...methods}>
                <form onSubmit={handleSubmit(onSubmit)}>
                  <Stack spacing={2}>
                    <Box display={'flex'} justifyContent="center">
                      <Box component="img" alt={'logo'} src={'/images/password_image.svg'} sx={{ maxWidth: 100 }} />
                    </Box>
                    <Typography variant="h4" fontWeight={'bold'} textAlign={'center'}>
                      Forgot your password?
                    </Typography>
                    <Typography variant="h6" textAlign={'center'}>
                      Please enter the email address associated with your account and We will email you a link to reset
                      your password.
                    </Typography>
                    {!!errors.email && <Alert severity="error">{errors.email.message}</Alert>}
                    <Controller
                      name="email"
                      control={control}
                      rules={{ required: true }}
                      render={({ field, fieldState: { error } }) => (
                        <TextField
                          name="email"
                          label="Email address*"
                          size="small"
                          focused
                          disabled={isSubmitSuccessful || isSubmitting}
                          color={!!errors.email ? 'warning' : 'grey'}
                          {...field}
                          fullWidth
                          value={typeof field.value === 'number' && field.value === 0 ? '' : field.value}
                          error={!!error}
                        />
                      )}
                    />
                    <LoadingButton
                      fullWidth
                      color="primary"
                      size="large"
                      type="submit"
                      variant="contained"
                      loading={isSubmitSuccessful || isSubmitting}
                    >
                      Send Request
                    </LoadingButton>
                    <Link
                      variant="body2"
                      color="inherit"
                      underline="always"
                      href="/login"
                      sx={{ cursor: 'pointer', textAlign: 'center' }}
                    >
                      Return to sign in
                    </Link>
                  </Stack>
                </form>
              </FormProvider>
            </Grid>
            <StyledSectionBg />
          </Grid>
        </StyledSection>
      </StyledRoot>
    </>
  );
}
