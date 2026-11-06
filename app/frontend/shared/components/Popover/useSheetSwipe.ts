import { type Ref } from "vue";

// How far, or how fast, a sheet has to be pulled to go rather than spring back.
const DISMISS_DISTANCE = 100;
const DISMISS_MIN_FLICK = 30;
const DISMISS_SPEED = 0.5;

/*
 * Pulling a sheet down by its body. Only from the top of its content, and only
 * for a gesture that begins there: a finger scrolling a long card back up must
 * not carry on into closing it.
 */
export const useSheetSwipe = (
  panel: Ref<HTMLElement | null>,
  active: () => boolean,
  dismiss: () => void,
) => {
  const offset = ref(0);
  const dragging = ref(false);

  let startY = 0;
  let startTime = 0;
  let tracking = false;

  const reset = () => {
    tracking = false;
    dragging.value = false;
    offset.value = 0;
  };

  const onTouchstart = (event: TouchEvent) => {
    if (!active() || event.touches.length !== 1) return;

    startY = event.touches[0].clientY;
    startTime = event.timeStamp;
    tracking = (panel.value?.scrollTop ?? 0) <= 0;
  };

  const onTouchmove = (event: TouchEvent) => {
    if (!tracking) return;

    const distance = event.touches[0].clientY - startY;

    if (!dragging.value && distance <= 0) {
      tracking = false;
      return;
    }

    dragging.value = true;
    offset.value = Math.max(0, distance);

    if (event.cancelable) event.preventDefault();
  };

  const onTouchend = (event: TouchEvent) => {
    if (!dragging.value) {
      tracking = false;
      return;
    }

    const distance = offset.value;
    const speed = distance / Math.max(1, event.timeStamp - startTime);
    const flicked = distance >= DISMISS_MIN_FLICK && speed >= DISMISS_SPEED;

    reset();

    if (distance >= DISMISS_DISTANCE || flicked) dismiss();
  };

  return {
    offset,
    dragging,
    reset,
    onTouchstart,
    onTouchmove,
    onTouchend,
  };
};
