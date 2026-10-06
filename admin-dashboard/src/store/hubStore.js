import { create } from 'zustand';

const initialState = {
  hubConnection: false,
};

const store = (set) => ({
  ...initialState,
  initHub: (bool) => {
    set({ hubConnection: bool });
  },
});

const hubStore = create(store);

export default hubStore;
