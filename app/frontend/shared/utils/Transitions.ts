/*
 * A CSS transition only animates if the browser painted the start state first.
 * `nextTick` only waits for Vue to patch the DOM, and a single
 * `requestAnimationFrame` still runs before that paint - so a class added there
 * can land in the same frame as the one that set the start position, and the
 * element jumps to its end state instead of travelling to it.
 *
 * Two frames guarantee the start state was painted. This replaces a
 * `setTimeout(..., 50)` guess that worked most of the time, which is what made
 * the off-canvas panel slide in from the middle now and then rather than from
 * its edge.
 */
export const afterNextPaint = (callback: () => void) => {
  requestAnimationFrame(() => {
    requestAnimationFrame(callback);
  });
};
