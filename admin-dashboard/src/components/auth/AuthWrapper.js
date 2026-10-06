import React, { useState, useEffect } from 'react';
import Cookies from 'js-cookie';
import apiService from '../apiService/apiService';
import userStore from '../../store/userStore';
import hydrationStore from '../../store/hydrationStore';

export default function AuthWrapper({ children }) {
  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);
  const company = hydrationStore(userStore, (state) => state.company);

  const cookieValue = Cookies.get('refreshToken');

  const getCompanyUser = async () => {
    await apiService()
      .post(`/Login/RefreshTokenCompany`, { token: cookieValue })
      .then((response) => {})
      .catch((error) => {});
  };

  useEffect(() => {
    getCompanyUser();
  }, []);

  return children;
}
