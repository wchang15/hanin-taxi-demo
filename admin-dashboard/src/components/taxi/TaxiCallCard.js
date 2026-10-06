import taxisStore from '../../store/taxisStore';
import apiService from '../apiService/apiService';
import userStore from '../../store/userStore';
import hydrationStore from '../../store/hydrationStore';
import CallingCard from './CallingCard';
import MatchingCard from './MatchingCard';
import PickUpCard from './PickUpCard';
import RidingCard from './RidingCard';
import ArrivedCard from './ArrivedCard';

export function TaxiCard({ call, setOpen, setNote, setPrice }) {
  const { cancelCall, handleCall, handleAddress, handleOption, handlePhoneNumber, initialAddress } = taxisStore();

  const jwtToken = hydrationStore(userStore, (state) => state.jwtToken);

  const handleCancelTrip = async (tripId) => {
    await apiService()
      .post(`/Company/CancelTrip?tripID=${tripId}`, null, {
        headers: {
          Authorization: `Bearer ${jwtToken}`,
          'Content-Type': 'application/json',
        },
      })
      .then((response) => {
        cancelCall(tripId);
      })
      .catch((error) => {
        console.log(error);
      });
  };

  switch (call.stage) {
    case 1:
      return (
        <>
          <CallingCard
            card={call}
            handleCall={handleCall}
            jwtToken={jwtToken}
            setNote={setNote}
            handleAddress={handleAddress}
            handleOption={handleOption}
            handlePhoneNumber={handlePhoneNumber}
            initialAddress={initialAddress}
          />
        </>
      );
    case 3:
      return (
        <MatchingCard
          card={call}
          setOpen={setOpen}
          cancelCall={() => {
            handleCancelTrip(call.id);
          }}
        />
      );
    case 4:
      return (
        <PickUpCard
          card={call}
          setOpen={setOpen}
          setNote={setNote}
          setPrice={setPrice}
          cancelCall={() => {
            handleCancelTrip(call.id);
          }}
        />
      );
    case 5:
      return <RidingCard card={call} setNote={setNote} setPrice={setPrice} />;
    case 6:
      return (
        <ArrivedCard
          card={call}
          cancelCall={() => {
            handleCancelTrip(call.id);
          }}
        />
      );
    default:
      <></>;
  }
}
