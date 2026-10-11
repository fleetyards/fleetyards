import { useEventListener } from "@vueuse/core";

/*
 * How far a row has to travel before letting go acts on it, and how far it
 * travels at most. Past the threshold the row follows the finger at a fraction
 * of its speed, which is what tells the reader the action is armed.
 */
export const SWIPE_THRESHOLD_PX = 80;
export const SWIPE_LIMIT_PX = 220;

// A finger never moves in a straight line. This much travel decides whether
// the gesture is a swipe or a scroll, and the other axis then gets none of it.
const LOCK_PX = 10;

const OVERSHOOT_DAMPING = 0.6;

// The click a tap would send arrives shortly after the finger lifts.
const CLICK_GUARD_MS = 400;

export type SwipeDirection = "left" | "right";

type UseSwipeActionsOptions = {
  target: Ref<HTMLElement | undefined> | ComputedRef<HTMLElement | undefined>;
  onSwipe: (direction: SwipeDirection) => void;
};

const damp = (travel: number) => {
  const magnitude = Math.abs(travel);

  if (magnitude <= SWIPE_THRESHOLD_PX) {
    return travel;
  }

  const damped = Math.min(
    SWIPE_THRESHOLD_PX + (magnitude - SWIPE_THRESHOLD_PX) * OVERSHOOT_DAMPING,
    SWIPE_LIMIT_PX,
  );

  return Math.sign(travel) * damped;
};

/*
 * Touch events rather than pointer events: they only ever come from a finger,
 * so a mouse drag never moves a row, and a touchscreen laptop still swipes.
 * The row declares `touch-action: pan-y`, which leaves vertical scrolling to
 * the browser and hands the horizontal travel to these listeners.
 */
export const useSwipeActions = ({
  target,
  onSwipe,
}: UseSwipeActionsOptions) => {
  const offset = ref(0);
  const swiping = ref(false);

  const direction = computed<SwipeDirection | undefined>(() => {
    if (offset.value > 0) return "right";
    if (offset.value < 0) return "left";

    return undefined;
  });

  const armed = computed(() => Math.abs(offset.value) >= SWIPE_THRESHOLD_PX);

  let startX = 0;
  let startY = 0;
  let tracking = false;
  let axis: "x" | "y" | undefined;
  let swipedAt = 0;

  const reset = () => {
    tracking = false;
    axis = undefined;
    swiping.value = false;
    offset.value = 0;
  };

  const onTouchStart = (event: TouchEvent) => {
    reset();

    // A new touch is a new gesture: a tap that starts now is meant.
    swipedAt = 0;

    if (event.touches.length !== 1) {
      return;
    }

    startX = event.touches[0].clientX;
    startY = event.touches[0].clientY;
    tracking = true;
  };

  const onTouchMove = (event: TouchEvent) => {
    if (!tracking) {
      return;
    }

    if (event.touches.length !== 1) {
      reset();

      return;
    }

    const dx = event.touches[0].clientX - startX;
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

    // An ancestor listening for a pull-to-refresh would otherwise read a
    // slightly downward swipe at the top of the page as a pull.
    event.stopPropagation();

    if (event.cancelable) {
      event.preventDefault();
    }

    swiping.value = true;
    offset.value = damp(dx);
  };

  const onTouchEnd = () => {
    if (!tracking) {
      return;
    }

    const swiped = axis === "x";
    const action = armed.value ? direction.value : undefined;

    reset();

    if (swiped) {
      swipedAt = Date.now();
    }

    if (action) {
      onSwipe(action);
    }
  };

  // The finger lifting off a row it has dragged must not also open it.
  const onClick = (event: MouseEvent) => {
    if (Date.now() - swipedAt < CLICK_GUARD_MS) {
      event.preventDefault();
      event.stopPropagation();
    }
  };

  useEventListener(target, "touchstart", onTouchStart, { passive: true });
  useEventListener(target, "touchmove", onTouchMove, { passive: false });
  useEventListener(target, "touchend", onTouchEnd);
  useEventListener(target, "touchcancel", reset);
  useEventListener(target, "click", onClick, { capture: true });

  return { offset, swiping, direction, armed };
};
