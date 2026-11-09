type AwaitCharacterOptions = {
  // The load under way, settling true once the figure is dressed in it and
  // false when another dressing overtook that one.
  pending: () => Promise<boolean> | undefined;
  redress: () => Promise<void>;
  stopped: () => boolean;
  timeout: number;
};

// Holds a figure back until it wears the character on its way. A character
// still not in when the time is up is put on once it lands, the figure being
// shown without it meanwhile: whether it was in time.
export const awaitCharacter = async ({
  pending,
  redress,
  stopped,
  timeout,
}: AwaitCharacterOptions) => {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const expired = new Promise<"expired">((resolve) => {
    timer = setTimeout(() => resolve("expired"), timeout);
  });

  try {
    const waited = new Set<Promise<boolean>>();
    for (
      let load = pending();
      load && !waited.has(load) && !stopped();
      load = pending()
    ) {
      waited.add(load);
      // A dressing that failed leaves the figure as it is: shown all the same.
      const dressed = await Promise.race([load.catch(() => true), expired]);
      if (dressed === "expired") return false;
      if (!dressed && !stopped()) await redress();
    }

    return true;
  } finally {
    clearTimeout(timer);
  }
};
