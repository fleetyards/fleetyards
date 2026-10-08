import type { WatchSource } from "vue";

interface TourAutostartOptions {
  // Whether the page is ready for the tour and the tour is due -- loaded,
  // unfiltered, not seen yet.
  ready: WatchSource<boolean>;
  start: () => void;
  // Lets the page's enter transition settle, so the first spotlight is
  // measured where it stays.
  delay?: number;
}

/*
 * Starts a tour on its own, at most once per visit of the page.
 *
 * Someone who clicks or types before it fires is already busy -- maybe in a
 * modal the tour would make inert -- so the start is dropped, not queued
 * behind them. An attempt spends it too, even one the tour refuses (a modal
 * open by itself): otherwise every refetch that flips `ready` off and on again
 * would bring it back in the middle of something else.
 */
export const useTourAutostart = ({
  ready,
  start,
  delay = 800,
}: TourAutostartOptions) => {
  let timer = 0;
  let spent = false;

  // Declared as functions: each removes the listener the other one is.
  function cancel() {
    window.clearTimeout(timer);
    document.removeEventListener("pointerdown", dismiss, true);
    document.removeEventListener("keydown", dismiss, true);
  }

  function dismiss() {
    spent = true;
    cancel();
  }

  watch(
    ready,
    (isReady) => {
      cancel();

      if (!isReady || spent) return;

      timer = window.setTimeout(() => {
        dismiss();
        start();
      }, delay);
      document.addEventListener("pointerdown", dismiss, true);
      document.addEventListener("keydown", dismiss, true);
    },
    { immediate: true },
  );

  onBeforeUnmount(cancel);
};
