export const debounce = (callback, delay) => {
  let timerId;

  const helperFunction = (...args) => {
    clearTimeout(timerId);

    timerId = setTimeout(() => {
      callback.apply(this, args);
    }, delay);
  };

  return helperFunction;
};

export const getLocationName = (preferredName, name, address) => {
  return preferredName !== '' ? `${preferredName} : ${name}, ${address}` : name !== '' ? `${name}, ${address}` : '';
};
