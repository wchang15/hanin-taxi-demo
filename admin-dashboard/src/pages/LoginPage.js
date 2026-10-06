import { Helmet } from 'react-helmet-async';
import { styled, alpha } from '@mui/material/styles';
import * as Yup from 'yup';
import { useState } from 'react';
import { yupResolver } from '@hookform/resolvers/yup';
import { useForm, FormProvider, Controller } from 'react-hook-form';
import { Link, Typography, Stack, Box, Alert, IconButton, InputAdornment, TextField } from '@mui/material';
import LoadingButton from '@mui/lab/LoadingButton';
import CreateAccountModal from '../components/login/CreateAccountModal';
import Logo from '../components/logo';
import Iconify from '../components/iconify';
import { bgGradient } from '../utils/cssStyles';
import apiService from '../components/apiService/apiService';
import userStore from '../store/userStore';

export const StyledRoot = styled('main')(() => ({
  height: '100%',
  display: 'flex',
  position: 'relative',
}));

export const StyledSection = styled('div')(({ theme }) => ({
  display: 'none',
  position: 'relative',
  [theme.breakpoints.up('md')]: {
    flexGrow: 1,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'column',
  },
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

export const StyledContent = styled('div')(({ theme }) => ({
  width: 480,
  margin: 'auto',
  display: 'flex',
  minHeight: '100vh',
  justifyContent: 'center',
  padding: theme.spacing(15, 2),
  [theme.breakpoints.up('md')]: {
    flexShrink: 0,
    padding: theme.spacing(30, 8, 0, 8),
  },
}));

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [open, setOpen] = useState(false);

  const defaultValues = {
    account: 'demo_company',
    password: 'demo1234',
  };

  const LoginSchema = Yup.object().shape({
    account: Yup.string().required('Account is required'),
    password: Yup.string().required('Password is required'),
  });

  const methods = useForm({
    resolver: yupResolver(LoginSchema),
    defaultValues,
  });

  const {
    reset,
    setError,
    handleSubmit,
    control,
    formState: { errors, isSubmitting, isSubmitSuccessful },
  } = methods;

  const loginUser = userStore((state) => state.setUser);

  const onSubmit = async (data) => {
    await apiService()
      .post(`/Login/LoginCompany`, {
        username: data.account,
        password: data.password,
      })
      .then((response) => {
        loginUser(response.data);
        window.location.href = '/dashboard';
      })
      .catch((error) => {
        reset();
        setError('afterSubmit', { type: 'custom', message: error.response.data });
      });
  };

  return (
    <>
      <Helmet>
        <title> Login | Hanin Taxi </title>
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
          <Typography variant="h3" sx={{ mb: 10, maxWidth: 480, textAlign: 'center' }}>
            안녕하세요, 반갑습니다
          </Typography>
          <Box component="img" alt={'logo'} src={'/logo/Logo_single.png'} sx={{ maxWidth: 186 }} />
          <StyledSectionBg />
        </StyledSection>
        <StyledContent>
          <Stack sx={{ width: 1 }}>
            <Stack spacing={2} sx={{ mb: 5, position: 'relative' }}>
              <Typography variant="h4">Sign in to Hanin Taxi</Typography>
              <Stack direction="row" spacing={0.5}>
                <Typography variant="body2">새로운 사용자이세요?</Typography>
                <Link variant="subtitle2" sx={{ cursor: 'pointer' }} onClick={() => setOpen(true)}>
                  아이디 만들기
                </Link>
              </Stack>
            </Stack>
            <FormProvider {...methods}>
              <form onSubmit={handleSubmit(onSubmit)}>
                <Stack>
                  {!!errors.afterSubmit && (
                    <Alert severity="error" sx={{ marginBottom: 2 }}>
                      {errors.afterSubmit.message}
                    </Alert>
                  )}
                  <Controller
                    name="account"
                    control={control}
                    rules={{ required: true }}
                    render={({ field, fieldState: { error } }) => (
                      <TextField
                        name="account"
                        label="아이디*"
                        size="small"
                        focused
                        disabled={isSubmitSuccessful || isSubmitting}
                        color={!!errors.account ? 'warning' : 'grey'}
                        {...field}
                        fullWidth
                        value={typeof field.value === 'number' && field.value === 0 ? '' : field.value}
                        error={!!error}
                      />
                    )}
                  />
                  {!!errors.account && (
                    <Typography variant="body2" sx={{ marginTop: 1, color: '#FF5630' }}>
                      {errors.account.message}
                    </Typography>
                  )}
                  <Controller
                    name="password"
                    control={control}
                    rules={{ required: true }}
                    render={({ field, fieldState: { error } }) => (
                      <TextField
                        sx={{ marginTop: 3 }}
                        {...field}
                        disabled={isSubmitSuccessful || isSubmitting}
                        fullWidth
                        value={typeof field.value === 'number' && field.value === 0 ? '' : field.value}
                        name="password"
                        label="비밀번호*"
                        size="small"
                        focused
                        color={!!errors.password ? 'warning' : 'grey'}
                        type={showPassword ? 'text' : 'password'}
                        InputProps={{
                          endAdornment: (
                            <InputAdornment position="end">
                              <IconButton onClick={() => setShowPassword(!showPassword)} edge="end">
                                {showPassword ? <Iconify icon="mdi:eye-off" /> : <Iconify icon="mdi:eye" />}
                              </IconButton>
                            </InputAdornment>
                          ),
                        }}
                      />
                    )}
                  />
                  {!!errors.password && (
                    <Typography variant="body2" sx={{ marginTop: 1, color: '#FF5630' }}>
                      {errors.password.message}
                    </Typography>
                  )}
                </Stack>
                <Stack alignItems="flex-end" sx={{ my: 2 }}>
                  <Link
                    variant="body2"
                    color="inherit"
                    underline="always"
                    sx={{ cursor: 'pointer' }}
                    href="/forgotpassword"
                  >
                    비밀번호를 잊어버리셨나요?
                  </Link>
                </Stack>

                <LoadingButton
                  fullWidth
                  color="primary"
                  size="large"
                  type="submit"
                  variant="contained"
                  loading={isSubmitSuccessful || isSubmitting}
                >
                  로그인
                </LoadingButton>
              </form>
            </FormProvider>
          </Stack>
        </StyledContent>
      </StyledRoot>
      <CreateAccountModal open={open} handleClose={() => setOpen(false)} />
    </>
  );
}
