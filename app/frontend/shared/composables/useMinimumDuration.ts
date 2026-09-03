// How long a waiting state has to stay up once it has gone up. A list that
// answers in 40ms would otherwise fill with placeholder bars and empty again
// before the eye settles, which reads as the page glitching rather than as the
// page loading - and the reader is left having seen something without being
// able to say what. Long enough to register as deliberate, short enough that a
// slow answer is still the thing being waited for.
export const MINIMUM_WAIT_MS = 400;

// Passes a flag through unchanged on the way up and holds it on the way down.
export const useMinimumDuration = (
  source: () => boolean,
  minimum = MINIMUM_WAIT_MS,
) => {
  const held = ref(source());

  let releaseAt = held.value ? Date.now() + minimum : 0;
  let timeout: ReturnType<typeof setTimeout> | undefined;

  const clear = () => {
    if (timeout) {
      clearTimeout(timeout);
      timeout = undefined;
    }
  };

  watch(source, (active) => {
    clear();

    if (active) {
      releaseAt = Date.now() + minimum;
      held.value = true;

      return;
    }

    const remaining = releaseAt - Date.now();

    if (remaining <= 0) {
      held.value = false;

      return;
    }

    timeout = setTimeout(() => {
      timeout = undefined;
      held.value = false;
    }, remaining);
  });

  onScopeDispose(clear);

  return held;
};
