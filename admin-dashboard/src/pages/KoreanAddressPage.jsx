import { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { Typography, Container, TextField } from '@mui/material';
import LoadingButton from '@mui/lab/LoadingButton';
import { toast } from 'react-toastify';
import AddressAutoComplete from '../components/taxi/AddressAutoComplete';
import userStore from '../store/userStore';
import hydrationStore from '../store/hydrationStore';
import Page404 from './Page404';
import apiService from '../components/apiService/apiService';

export default function KoreanAddressPage({ setIsLoading }) {
  const company = hydrationStore(userStore, (state) => state.company);
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);
  const [address, setAddress] = useState(null);
  const [refresh, setRefresh] = useState(true);
  const [name, setName] = useState('');

  useEffect(() => {
    setRefresh(!refresh);
  }, []);

  const handleAddressSelect = (selected) => {
    if (selected != null) {
      setAddress(selected);
    } else {
      setAddress(null);
    }
  };

  const submitName = () => {
    saveAddress();
  };

  const saveAddress = async () => {
    setIsLoading(true);
    if (company && jwtToken) {
      try {
        const response = await apiService().post(
          `/Shared/SaveAddress`,
          {
            preferredName: name,
            name: address.name,
            address: address.address,
            latitude: address.latitude,
            longitude: address.longitude,
            locationType: address.locationType,
          },
          {
            headers: {
              Authorization: `Bearer ${jwtToken}`,
              'Content-Type': 'application/json',
            },
          }
        );

        if (response !== null && response.status === 200) {
          setAddress(null);
          setRefresh(!refresh);
          setName('');
          toast.success('Saved');
        } else {
          toast.error(response.data);
        }
      } catch (err) {
        toast.error(err.message);
      }
    }
    setIsLoading(false);
  };

  return (
    <>
      {company == null || jwtToken === null ? (
        <Page404 />
      ) : (
        <>
          <Helmet>
            <title> 한국어 주소 | Hanin Taxi </title>
          </Helmet>
          <Container>
            <Typography variant="h4" gutterBottom sx={{ mb: 5 }}>
              Taxi
            </Typography>
            <TextField
              fullWidth
              size="small"
              value={name}
              placeholder="한글 이름을 입력하세요"
              name="name"
              onChange={(e) => {
                setName(e.target.value);
              }}
              sx={{ mb: 2 }}
            />
            <AddressAutoComplete handleSelect={handleAddressSelect} jwtToken={jwtToken} refresh={refresh} />
            <LoadingButton variant="contained" fullWidth sx={{ color: 'white', my: 2 }} onClick={submitName}>
              저장
            </LoadingButton>
          </Container>
        </>
      )}
    </>
  );
}
