import { create } from 'zustand';
import {  persist, createJSONStorage } from 'zustand/middleware';
import Cookies from 'js-cookie';

const initialState = {
  company: null,
  refreshToken: '',
  jwtToken: '',
};

const store = (set) => ({
  ...initialState,
  setUser: (result) => {
    set({
      company: result.company,
      refreshToken: result.refreshToken,
      jwtToken: result.token,
    });
   
    Cookies.set('refreshToken', result.refreshToken)
    return true;
  },

  reset: () => {
    set({ initialState });
    Cookies.remove('refreshToken')
    return true;
  },
});

const userStore = create(persist(store, { name: 'taxis', storage: createJSONStorage(() => localStorage) }));

export default userStore;
