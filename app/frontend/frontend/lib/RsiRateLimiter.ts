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

  // Gives up without a slot once `signal` aborts, so a cancel need not wait
  // for the next one.
  const take = async (signal?: AbortSignal) => {
    while (!signal?.aborted && !tryTake()) {
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  };

  // For specs, which would otherwise spend one budget across a whole file.
  const reset = () => {
    sentAt = [];
  };

  return { tryTake, take, reset };
};

// Every sync that reads RSI takes its requests from this one budget, so the
// hangar sync, the buy-back list and the price pass can run side by side and
// still stay inside the limit together.
export const rsiRateLimiter = createRsiRateLimiter(60);
