import { MINIMUM_WAIT_MS } from "@/shared/composables/useMinimumDuration";

/*
 * How far the indicator travels before the pull is armed, and where it stops
 * following the finger. Both are the indicator's travel rather than the
 * finger's: the pull is damped, so the finger covers twice as much.
 */
export const PULL_THRESHOLD_PX = 72;
export const PULL_LIMIT_PX = 108;

// Undamped, the threshold is crossed before the gesture reads as deliberate,
// and every downward flick at the top of a list refetches the page.
const PULL_DAMPING = 0.5;

type UsePullToRefreshOptions = {
  target: Ref<HTMLElement | null> | ComputedRef<HTMLElement | null>;
  refresh: () => Promise<unknown> | unknown;
  disabled?: Ref<boolean> | ComputedRef<boolean>;
};

export const usePullToRefresh = ({
  target,
  refresh,
  disabled,
}: UsePullToRefreshOptions) => {
  const distance = ref(0);
  const pulling = ref(false);
  const refreshing = ref(false);

  const armed = computed(() => distance.value >= PULL_THRESHOLD_PX);

  // Negative while iOS rubber-bands the document, which is the middle of the
  // gesture we are here to read - so anything at or above the top counts.
  const atTop = () =>
    (window.scrollY || document.documentElement.scrollTop) <= 0;

  /*
   * A pull that starts inside something holding its own scroll position belongs
   * to that scroller, not to the page: a table scrolled halfway down would
   * otherwise refetch on the way back up. A canvas is excluded outright,
   * because the 3D views read the drag themselves.
   */
  const ownedByContent = (from: EventTarget | null, root: HTMLElement) => {
    let node = from instanceof Element ? from : null;

    while (node && node !== root) {
      if (node.tagName === "CANVAS" || node.scrollTop > 0) {
        return true;
      }

      node = node.parentElement;
    }

    return false;
  };

  let floor: ReturnType<typeof setTimeout> | undefined;

  const clearFloor = () => {
    if (floor) {
      clearTimeout(floor);
      floor = undefined;
    }
  };

  const waitOutFloor = () =>
    new Promise((resolve) => {
      floor = setTimeout(resolve, MINIMUM_WAIT_MS);
    });

  let startY = 0;
  let tracking = false;

  const release = () => {
    tracking = false;
    pulling.value = false;
    distance.value = 0;
  };

  const onTouchStart = (event: TouchEvent) => {
    tracking = false;

    if (refreshing.value || disabled?.value) {
      return;
    }

    if (event.touches.length !== 1 || !atTop() || !target.value) {
      return;
    }

    if (ownedByContent(event.target, target.value)) {
      return;
    }

    startY = event.touches[0].clientY;
    tracking = true;
  };

  const onTouchMove = (event: TouchEvent) => {
    if (!tracking) {
      return;
    }

    if (event.touches.length !== 1 || !atTop()) {
      release();

      return;
    }

    const delta = event.touches[0].clientY - startY;

    // The finger turned back past where it started: this is a scroll after all,
    // and the page gets the rest of the gesture untouched.
    if (delta <= 0) {
      release();

      return;
    }

    // Nothing may scroll or bounce under a pull we have taken over, or the
    // content and the indicator travel down together.
    if (event.cancelable) {
      event.preventDefault();
    }

    pulling.value = true;
    distance.value = Math.min(delta * PULL_DAMPING, PULL_LIMIT_PX);
  };

  // A query that fails reports itself through its own error state; all the
  // indicator owes it is to stop.
  const ignoreRefreshError = () => undefined;

  const onTouchEnd = async () => {
    if (!tracking) {
      return;
    }

    tracking = false;
    pulling.value = false;

    if (!armed.value) {
      distance.value = 0;

      return;
    }

    refreshing.value = true;

    // Parked at the threshold rather than wherever the finger stopped: the
    // spinner has to hold still while it spins.
    distance.value = PULL_THRESHOLD_PX;

    await Promise.all([
      Promise.resolve().then(refresh).catch(ignoreRefreshError),
      waitOutFloor(),
    ]);

    clearFloor();

    refreshing.value = false;
    distance.value = 0;
  };

  const handleTouchEnd = () => {
    void onTouchEnd();
  };

  let attached: HTMLElement | null = null;

  const detach = () => {
    if (!attached) {
      return;
    }

    attached.removeEventListener("touchstart", onTouchStart);
    attached.removeEventListener("touchmove", onTouchMove);
    attached.removeEventListener("touchend", handleTouchEnd);
    attached.removeEventListener("touchcancel", release);
    attached = null;
  };

  const attach = (element: HTMLElement | null) => {
    detach();

    if (!element) {
      return;
    }

    element.addEventListener("touchstart", onTouchStart, { passive: true });
    // The one listener that cannot be passive: it is what keeps the page from
    // scrolling under the pull.
    element.addEventListener("touchmove", onTouchMove, { passive: false });
    element.addEventListener("touchend", handleTouchEnd);
    element.addEventListener("touchcancel", release);

    attached = element;
  };

  watch(target, attach, { immediate: true });

  // A drawer or a modal opening mid-pull takes the gesture with it.
  watch(
    () => disabled?.value,
    (off) => {
      if (off && !refreshing.value) {
        release();
      }
    },
  );

  onScopeDispose(() => {
    detach();
    clearFloor();
  });

  return { distance, pulling, refreshing, armed };
};
