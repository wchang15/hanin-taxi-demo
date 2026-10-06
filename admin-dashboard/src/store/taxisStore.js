import { create } from 'zustand';
import { EnumLocationType } from '../_mock/taxi';

const intialCallObject = {
  id: 0,
  address: '',
  addressTitle: '',
  longitude: '',
  latitude: '',
  locationType: 7,
  option: 2,
  stage: 1,
  phone: '',
  notes: null,
  assignedDriver: null,
  companyTripPrice: null,
};


const intialCallObjectList = [];

const initialState = {
  calls: intialCallObjectList,
};

const store = (set, get) => ({
  ...initialState,
  addACall: () => {
    set((state) => ({
      calls: [...state.calls, { ...intialCallObject, id: `draft-${crypto.randomUUID()}` }],
    }));
  },

  setCalls: (c) => {
    set(() => ({
      calls: c,
    }));
  },

  reset: () => {
    set(() => ({
      calls: [intialCallObject],
    }));
  },

  cancelCall: (id) => {
    set((state) => ({
      calls: state.calls.filter((call) => call.id !== id),
    }));
  },

  deleteAllArrival: () => {
    set((state) => ({
      calls: state.calls.filter((call) => call.stage !== 6),
    }));
  },

  handleCall: (update, id) => {
    set((state) => ({
      calls: state.calls.map((call) => (call.id === id ? update : call)),
    }));
  },

  handleNote: (note, id) => {
    set((state) => ({
      calls: state.calls.map((call) => (call.id === id ? { ...call, notes: note } : call)),
    }));
  },

  handlePrice: (amount, id) => {
    set((state) => ({
      calls: state.calls.map((call) => (call.id === id ? { ...call, companyTripPrice: amount } : call)),
    }));
  },

  handlePhoneNumber: (num, id) => {
    set((state) => ({
      calls: state.calls.map((call) => (call.id === id ? { ...call, phone: num } : call)),
    }));
  },

  handleCompanyCancel: (id) => {
    const callCopy = get().calls;
    const index = callCopy.findIndex((element) => element.id === id);
    if (index !== -1) {
      callCopy.splice(index, 1);
    }
    set(() => ({
      calls: callCopy,
    }));
  },

  handleUpdate: (trips) => {
    const oldCalls = get().calls;
    const newSet = new Set();

    const updateCalls = [];

    oldCalls.forEach((oldCall) => {
      if (typeof oldCall.id === 'string') updateCalls.push(oldCall);
      const matchingNewCall = trips.find((trip) => trip.id === oldCall.id);
      if (matchingNewCall) {
        newSet.add(matchingNewCall.id);
        updateCalls.push(matchingNewCall);
      }
    });

    trips.forEach((trip) => {
      if (!newSet.has(trip.id)) {
        updateCalls.push(trip);
      }
    });

    set(() => ({
      calls: updateCalls,
    }));
  },

  handleAddress: async (address, id) => {
    set((state) => ({
      calls: state.calls.map((call) =>
        call.id === id
          ? {
              ...call,
              address: address.address,
              addressTitle: address.name,
              longitude: address.longitude,
              latitude: address.latitude,
              locationType: address.locationType,
            }
          : call
      ),
    }));
  },

  setCall: (trip) => {
    const callCopy = get().calls;
    const isObjectInList = callCopy.some((obj) => obj.id === trip.id);
    if (!isObjectInList) {
      callCopy.push(trip);
    }

    set(() => ({
      calls: callCopy,
    }));
  },

  initialAddress: (id) => {
    set((state) => ({
      calls: state.calls.map((call) =>
        call.id === id
          ? {
              ...call,
              address: '',
              addressTitle: '',
              longitude: '',
              latitude: '',
              locationType: EnumLocationType.OTHER,
            }
          : call
      ),
    }));
  },

  handleOption: (opt, id) => {
    set((state) => ({
      calls: state.calls.map((call) => (call.id === id ? { ...call, option: opt } : call)),
    }));
  },
});

const taxisStore = create(store);

export default taxisStore;
