export const tripConvert = (elem) => {
  console.log('tripconvert', elem);

  const driverObject = {
    driverNumber: elem.driverNumber,
    carplate: elem.licensePlate,
    make: elem.make,
    color: elem.color,
    phonenumber: elem.driverPhoneNumber,
    companyName: '',
  };

  const convertedTrip = {
    id: elem.tripID,
    address: elem.startAddress,
    addressTitle:
      elem.startPreferredName != null && elem.startPreferredName !== '' ? elem.startPreferredName : elem.startName,
    longitude: elem.startLongitude,
    latitude: elem.startLatitude,
    startFullAddress: elem.startName.concat(', ', elem.startAddress),
    endFullAddress: elem.endName && elem.endName.concat(', ', elem.endAddress),
    locationType: elem.locationType,
    option: 1, // option
    stage: elem.tripStatus,
    phone: elem.phonenumber,
    notes: elem.notes,
    price: null,
    assignedDriver: driverObject, // driver
    companyTripPrice: elem.companyTripPrice,
    dropOffaddress:
      elem.endPreferredName != null && elem.endPreferredName !== '' ? elem.endPreferredName : elem.endName,
  };

  return convertedTrip;
};
