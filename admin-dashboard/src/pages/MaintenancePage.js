import { Helmet } from 'react-helmet-async';
import { Container } from '@mui/material';

export default function MaintenancePage() {
  return (
    <>
      <Helmet>
        <title> 설정 | Hanin Taxi </title>
      </Helmet>
      <Container maxWidth={false}>Maintenance Page</Container>
    </>
  );
}
