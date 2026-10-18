import { useEventListener } from "@vueuse/core";

// A finger never moves in a straight line. This much travel decides whether
// the gesture is a swipe or a scroll, and the other axis then gets none of it.
const LOCK_PX = 10;

// Past half the panel's width letting go closes it, as a native drawer does.
const DISMISS_FRACTION = 0.5;

// A flick closes the panel however short it was, in px per ms.
const FLICK_VELOCITY = 0.4;

/*
 * The flick is the finger's speed over its last stretch of at least
 * FLICK_SPAN_MS, not between its last two moves: those can arrive a
 * millisecond apart and read as any speed at all. A finger whose last move is
 * older than FLICK_WINDOW_MS came to rest before lifting, and has not flicked.
 * The stretch never reaches back past the finger's last turn, or a flick back
 * would be averaged into the drag before it.
 */
const FLICK_SPAN_MS = 20;
const FLICK_WINDOW_MS = 100;

export type SwipeToDismissSide = "left" | "right";

type UseSwipeToDismissOptions = {
  panel: Ref<HTMLElement | null | undefined>;
  // The edge the panel is anchored to, and so the direction it leaves in.
  side: MaybeRefOrGetter<SwipeToDismissSide>;
  enabled: MaybeRefOrGetter<boolean>;
  onDismiss: () => void;
};

/*
 * A horizontal drag that starts inside one of these belongs to it: a range
 * slider, a caret, a table scrolled sideways, a 3D view.
 */
const ownedByContent = (from: EventTarget | null) => {
  let node = from instanceof Element ? from : null;

  while (node && node !== document.body) {
    if (
      ["INPUT", "TEXTAREA", "SELECT", "CANVAS"].includes(node.tagName) ||
      node.getAttribute("role") === "slider" ||
      (node instanceof HTMLElement && node.isContentEditable)
    ) {
      return true;
    }

    if (node.scrollWidth > node.clientWidth) {
      const { overflowX } = getComputedStyle(node);

      if (overflowX === "auto" || overflowX === "scroll") {
        return true;
      }
    }

    node = node.parentElement;
  }

  return false;
};

/*
 * Drags an open panel back towards the edge it came from, the way a drawer on
 * iOS follows the finger and either closes or springs back on release.
 *
 * The listeners sit on the document rather than the panel: while a drawer is
 * open, everything beside it is its backdrop, and a drag across the dimmed page
 * closes it too.
 */
export const useSwipeToDismiss = ({
  panel,
  side,
  enabled,
  onDismiss,
}: UseSwipeToDismissOptions) => {
  // Signed like the panel's `translateX`: negative moves a left panel out.
  const offset = ref(0);
  const dragging = ref(false);

  const width = () => panel.value?.offsetWidth || 0;

  // Travel towards the closed position, positive however the panel is anchored.
  const towardsClosed = (dx: number) => (toValue(side) === "left" ? -dx : dx);

  const progress = computed(() => {
    const total = width();

    if (!total) {
      return 0;
    }

    return Math.min(Math.abs(offset.value) / total, 1);
  });

  let startX = 0;
  let startY = 0;
  let samples: { x: number; time: number }[] = [];
  let tracking = false;
  let axis: "x" | "y" | undefined;

  const reset = () => {
    tracking = false;
    axis = undefined;
    samples = [];
    dragging.value = false;
    offset.value = 0;
  };

  const onTouchStart = (event: TouchEvent) => {
    reset();

    if (event.touches.length !== 1 || !toValue(enabled)) {
      return;
    }

    if (ownedByContent(event.target)) {
      return;
    }

    startX = event.touches[0].clientX;
    startY = event.touches[0].clientY;
    samples = [{ x: startX, time: event.timeStamp }];
    tracking = true;
  };

  const onTouchMove = (event: TouchEvent) => {
    if (!tracking) {
      return;
    }

    if (event.touches.length !== 1 || !toValue(enabled)) {
      reset();

      return;
    }

    const x = event.touches[0].clientX;
    const dx = x - startX;
    const dy = event.touches[0].clientY - startY;

    if (!axis) {
      if (Math.abs(dx) > LOCK_PX && Math.abs(dx) > Math.abs(dy)) {
        axis = "x";
      } else if (Math.abs(dy) > LOCK_PX) {
        axis = "y";
      }
    }

    if (axis === "y") {
      reset();

      return;
    }

    if (axis !== "x") {
      return;
    }

    if (event.cancelable) {
      event.preventDefault();
    }

    samples.push({ x, time: event.timeStamp });
    samples = samples.filter(
      ({ time }) => event.timeStamp - time <= FLICK_WINDOW_MS,
    );

    // Held at the open position rather than pulled past it: the panel is
    // anchored to the edge, and further in would open a gap behind it.
    const travel = Math.min(Math.max(towardsClosed(dx), 0), width());

    dragging.value = true;
    offset.value = toValue(side) === "left" ? -travel : travel;
  };

  const flickVelocity = (endedAt: number) => {
    const last = samples[samples.length - 1];

    if (!last || endedAt - last.time > FLICK_WINDOW_MS) {
      return 0;
    }

    let turn = samples.length - 1;
    const direction = Math.sign(last.x - (samples[turn - 1]?.x ?? last.x));

    while (
      turn > 0 &&
      Math.sign(samples[turn].x - samples[turn - 1].x) !== -direction
    ) {
      turn -= 1;
    }

    const since = samples.slice(turn);
    const from =
      since.findLast(({ time }) => last.time - time >= FLICK_SPAN_MS) ||
      since[0];
    const span = last.time - from.time;

    return span > 0 ? towardsClosed(last.x - from.x) / span : 0;
  };

  const onTouchEnd = (event: TouchEvent) => {
    if (!tracking) {
      return;
    }

    const velocity = flickVelocity(event.timeStamp);

    const travel = Math.abs(offset.value);
    const flicked = velocity > FLICK_VELOCITY;
    const flickedBack = velocity < -FLICK_VELOCITY;

    const dismiss =
      axis === "x" &&
      travel > 0 &&
      (flicked || (!flickedBack && travel > width() * DISMISS_FRACTION));

    // Reset first and dismiss in the same tick, so the panel's own transition
    // carries it from where the finger left it.
    reset();

    if (dismiss) {
      onDismiss();
    }
  };

  watch(
    () => toValue(enabled),
    (isEnabled) => {
      if (!isEnabled) {
        reset();
      }
    },
  );

  // Only while the panel is open: a non-passive touchmove on the document makes
  // every scroll on the page wait for the main thread.
  const listenOn = () => (toValue(enabled) ? document : undefined);

  useEventListener(listenOn, "touchstart", onTouchStart, { passive: true });
  useEventListener(listenOn, "touchmove", onTouchMove, { passive: false });
  useEventListener(listenOn, "touchend", onTouchEnd);
  useEventListener(listenOn, "touchcancel", reset);

  return { offset, dragging, progress };
};
