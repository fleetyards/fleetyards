import debounce from "lodash.debounce";

export const REFRESH_WAIT_MS = 500;

/*
 * A refresh that collapses a burst of calls into one and stops with the
 * component. A channel can deliver several broadcasts in a row -- a hangar
 * import files one message per vehicle -- and the page only has to catch up
 * once. The timer is the reason this is a composable rather than a bare
 * `debounce`: a broadcast that lands just before a navigation would otherwise
 * refetch into a page that is already gone, because unsubscribing from the
 * channel cancels nothing.
 */
export const useDebouncedRefresh = (
  refresh: () => unknown,
  wait = REFRESH_WAIT_MS,
) => {
  const debounced = debounce(() => {
    void refresh();
  }, wait);

  onUnmounted(() => {
    debounced.cancel();
  });

  return debounced;
};
