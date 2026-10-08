const WINDOW = 60_000;

// At most `perMinute` requests to RSI in any sixty seconds. Budget a crawl
// left unused does not carry over into a burst for the pass after it. A pass
// that outlives the modal holds only this, not the modal that made it.
export const createRsiRateLimiter = (perMinute: number) => {
  let sentAt: number[] = [];

  const tryTake = () => {
    const now = Date.now();
    sentAt = sentAt.filter((time) => now - time < WINDOW);

    if (sentAt.length >= perMinute) return false;

    sentAt.push(now);

    return true;
  };

  const take = async () => {
    while (!tryTake()) {
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  };

  return { tryTake, take };
};
