import { differenceInMinutes } from "date-fns";

// A budget of `perMinute` requests to RSI for every minute since it was made,
// so a slow start is made up later. A pass that outlives the modal holds only
// this, not the modal that made it.
export const createRsiRateLimiter = (perMinute: number) => {
  const startedAt = new Date();

  let count = 0;

  const available = () =>
    count < (differenceInMinutes(new Date(), startedAt) + 1) * perMinute;

  const tryTake = () => {
    if (!available()) return false;

    count += 1;

    return true;
  };

  const take = async () => {
    while (!tryTake()) {
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  };

  return { tryTake, take };
};
