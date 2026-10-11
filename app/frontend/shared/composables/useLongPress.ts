import { useEventListener } from "@vueuse/core";
import { canVibrateNow, hapticTick } from "@/shared/utils/Haptics";

// Long enough that a tap or the start of a scroll never trips it, short enough
// that a held finger does not wonder whether anything is happening. The
// platforms' own long press sits at about the same.
export const LONG_PRESS_MS = 500;

// A finger resting on glass still drifts a few pixels. More than this and it
// is a scroll or a swipe, not a hold.
const MOVE_TOLERANCE_PX = 10;

// The click a tap would send arrives shortly after the finger lifts.
const CLICK_GUARD_MS = 400;

type UseLongPressOptions = {
  target: Ref<HTMLElement | undefined> | ComputedRef<HTMLElement | undefined>;
  onLongPress: () => void;
};

/*
 * Touch events only, like useSwipeActions: a mouse has a right button and a
 * keyboard has a checkbox to reach, so holding is a finger's way in alone.
 */
export const useLongPress = ({ target, onLongPress }: UseLongPressOptions) => {
  let timer: ReturnType<typeof setTimeout> | undefined;
  let startX = 0;
  let startY = 0;
  let pressedAt = 0;

  // Whether the click arriving now is the one a lifted finger sends after a
  // hold, for a listener that cannot count on running after this one's guard.
  const justHeld = () => Date.now() - pressedAt < CLICK_GUARD_MS;

  // A second finger that lands outside the row never reaches the row's own
  // listeners, so the document watches for it while a hold is pending.
  const onAnyTouchStart = (event: TouchEvent) => {
    if (event.touches.length > 1) {
      cancel();
    }
  };

  const cancel = () => {
    clearTimeout(timer);
    timer = undefined;
    document.removeEventListener("touchstart", onAnyTouchStart);
  };

  const onTouchStart = (event: TouchEvent) => {
    cancel();
    pressedAt = 0;

    if (event.touches.length !== 1) {
      return;
    }

    startX = event.touches[0].clientX;
    startY = event.touches[0].clientY;

    document.addEventListener("touchstart", onAnyTouchStart, { passive: true });

    timer = setTimeout(() => {
      cancel();
      pressedAt = Date.now();

      // The tick says the hold landed while the finger is still down, the way
      // a native list answers a long press - where the device can buzz from a
      // timer. Elsewhere it comes as the finger lifts.
      if (canVibrateNow()) {
        hapticTick();
      }

      onLongPress();
    }, LONG_PRESS_MS);
  };

  const onTouchMove = (event: TouchEvent) => {
    if (!timer) {
      return;
    }

    if (event.touches.length !== 1) {
      cancel();

      return;
    }

    const dx = event.touches[0].clientX - startX;
    const dy = event.touches[0].clientY - startY;

    if (Math.hypot(dx, dy) > MOVE_TOLERANCE_PX) {
      cancel();
    }
  };

  // The finger lifting off a row it has held must not also open it.
  const onClick = (event: MouseEvent) => {
    if (justHeld()) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  };

  // Android answers a held finger with a context menu, which would open over
  // the selection the hold just started.
  const onContextMenu = (event: Event) => {
    if (timer || Date.now() - pressedAt < CLICK_GUARD_MS) {
      event.preventDefault();
    }
  };

  useEventListener(target, "touchstart", onTouchStart, { passive: true });
  useEventListener(target, "touchmove", onTouchMove, { passive: true });
  const onTouchEnd = () => {
    cancel();

    if (justHeld() && !canVibrateNow()) {
      hapticTick();
    }
  };

  useEventListener(target, "touchend", onTouchEnd);
  useEventListener(target, "touchcancel", cancel);
  useEventListener(target, "click", onClick, { capture: true });
  useEventListener(target, "contextmenu", onContextMenu);

  onBeforeUnmount(cancel);

  return { justHeld };
};
