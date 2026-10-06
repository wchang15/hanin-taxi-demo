import axios from 'axios';
import { APIADDRESS } from '../../utils/constants';

export default function apiService() {
  const instance = axios.create({
    baseURL: APIADDRESS,
  });
  return instance;
}

// This is prod api (API not ready yet)
