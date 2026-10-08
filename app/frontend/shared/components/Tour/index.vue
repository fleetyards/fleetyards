<script lang="ts">
export default {
  name: "AppTour",
};
</script>

<script lang="ts" setup>
import { useResizeObserver } from "@vueuse/core";
import { routerKey } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";
import { placeFloating } from "@/shared/utils/floatingPlacement";
import type { TourEndReason, TourStep } from "./types";

interface Props {
  steps: TourStep[];
  // Where focus goes when the element that started the tour is gone or hidden
  // by then -- an item in a dropdown menu that closed when it was picked.
  returnFocusFallback?: string;
}

const props = withDefaults(defineProps<Props>(), {
  returnFocusFallback: undefined,
});

const open = defineModel<boolean>("open", { default: false });

const emit = defineEmits<{
  // Emitted once the tour is actually on screen, which a request to open it
  // does not guarantee: no step may be showable, or a modal may be open.
  start: [];
  end: [reason: TourEndReason];
}>();

const { t } = useI18n();

const { prefersReducedMotion } = useReducedMotion();

// Injected rather than `useRouter()`: a tour whose steps name no route works
// without one, and a page-bound tour's specs mount it bare.
const router = inject(routerKey, null);

// How long a step on another page waits for its target to render after the
// navigation -- data loading in -- before it is passed over or centred.
const TARGET_WAIT = 5000;
const TARGET_POLL = 100;

const HOLE_PADDING = 6;
const GAP = 12;
const MARGIN = 12;

const titleId = useId();
const textId = useId();

const root = ref<HTMLElement | null>(null);
const card = ref<HTMLElement | null>(null);

// The ids picked at start; the steps themselves are read from the props, so
// their text follows a locale change.
const shownIds = ref<string[]>([]);

// Steps on another page cannot be checked at start; one whose required target
// never rendered there is dropped once the tour has looked.
const passedOver = ref<string[]>([]);

// Between leaving one page and the next step's target rendering. The card is
// hidden and Next / Back wait, so a second press cannot race the navigation.
const navigating = ref(false);

// Rendered once a start has committed, not merely once asked to open: a start
// that refuses closes the tour without it ever flashing on screen.
const visible = ref(false);
const shown = computed<TourStep[]>(() =>
  shownIds.value
    .filter((id) => !passedOver.value.includes(id))
    .map((id) => props.steps.find((step) => step.id === id))
    .filter((step): step is TourStep => !!step),
);
const index = ref(0);
const hole = ref<{
  top: number;
  left: number;
  width: number;
  height: number;
} | null>(null);
const cardPosition = ref<{ top: number; left: number } | null>(null);

const current = computed<TourStep | undefined>(() => shown.value[index.value]);
const isFirst = computed(() => index.value === 0);
const isLast = computed(() => index.value === shown.value.length - 1);

// `display: none` and detached nodes have no boxes; a control teleported away
// on mobile or hidden by a flag is simply not found.
const isRendered = (element: Element) => element.getClientRects().length > 0;

const isElsewhere = (step: TourStep) =>
  !!step.route &&
  !!router &&
  router.resolve(step.route).path !== router.currentRoute.value.path;

const findTarget = (step?: TourStep): HTMLElement | null => {
  if (!step?.target) return null;

  return (
    Array.from(document.querySelectorAll<HTMLElement>(step.target)).find(
      isRendered,
    ) ?? null
  );
};

// Inside the middle of the window rather than merely inside it: a fixed header
// covers the top, and a control under it would be spotlit but unseen.
const comfortablyVisible = (rect: DOMRect) =>
  rect.top >= window.innerHeight * 0.15 &&
  rect.bottom <= window.innerHeight * 0.85 &&
  rect.left >= 0 &&
  rect.right <= window.innerWidth;

// Resolved once per step rather than on every scroll frame; looked up again
// only when the page re-rendered it.
let target: HTMLElement | null = null;

const currentTarget = () => {
  if (!target?.isConnected) target = findTarget(current.value);

  return target;
};

const place = () => {
  if (navigating.value) return;

  const element = currentTarget();

  if (element) {
    const rect = element.getBoundingClientRect();
    hole.value = {
      top: rect.top - HOLE_PADDING,
      left: rect.left - HOLE_PADDING,
      width: rect.width + HOLE_PADDING * 2,
      height: rect.height + HOLE_PADDING * 2,
    };
  } else {
    hole.value = null;
  }

  if (!card.value) return;

  const box = card.value.getBoundingClientRect();

  if (!hole.value) {
    cardPosition.value = {
      top: Math.max(MARGIN, (window.innerHeight - box.height) / 2),
      left: Math.max(MARGIN, (window.innerWidth - box.width) / 2),
    };
    return;
  }

  const anchor = new DOMRect(
    hole.value.left,
    hole.value.top,
    hole.value.width,
    hole.value.height,
  );

  // A narrow screen has no room beside a control, only above or below it.
  const narrow = window.innerWidth < box.width * 2 + GAP * 2;
  const requested = current.value?.placement ?? "bottom";
  const placement =
    narrow && (requested === "left" || requested === "right")
      ? "bottom"
      : requested;

  const { top, left } = placeFloating(anchor, box, placement, {
    gap: GAP,
    margin: MARGIN,
    flip: true,
  });

  cardPosition.value = { top, left };
};

let frame = 0;

const schedulePlace = () => {
  window.cancelAnimationFrame(frame);
  frame = window.requestAnimationFrame(place);
};

const focusCard = () => {
  card.value?.focus({ preventScroll: true });
};

const waitForTarget = (step: TourStep, own: number) =>
  new Promise<HTMLElement | null>((resolve) => {
    const deadline = Date.now() + TARGET_WAIT;

    const poll = () => {
      const element = findTarget(step);

      if (
        own !== session ||
        element ||
        !step.target ||
        Date.now() >= deadline
      ) {
        resolve(element);
      } else {
        window.setTimeout(poll, TARGET_POLL);
      }
    };

    poll();
  });

// Goes to the step's page first when it names another one. Back takes the
// same route, so it returns to the page the previous step was shown on.
const showStep = async (next: number, direction: 1 | -1 = 1) => {
  const own = session;
  const step = shown.value[next];

  if (!step) {
    end("finished");
    return;
  }

  index.value = next;
  target = null;

  if (step.route && router) {
    navigating.value = true;
    hole.value = null;
    cardPosition.value = null;

    if (isElsewhere(step)) await router.push(step.route).catch(() => {});

    const found = own === session ? await waitForTarget(step, own) : null;

    if (own !== session) return;

    navigating.value = false;

    if (!found && step.requiresTarget) {
      passedOver.value = [...passedOver.value, step.id];

      // Forwards, the same index now names the following step; backwards, the
      // one before -- and with none before, the walk turns round.
      const following = direction === 1 || next === 0 ? next : next - 1;

      await showStep(following, next === 0 ? 1 : direction);
      return;
    }
  }

  await nextTick();

  if (own !== session) return;

  const element = currentTarget();

  if (element && !comfortablyVisible(element.getBoundingClientRect())) {
    element.scrollIntoView({
      block: "center",
      inline: "nearest",
      behavior: prefersReducedMotion.value ? "auto" : "smooth",
    });
  }

  place();

  // The card stays hidden until it has a position, and a hidden element
  // cannot take focus.
  await nextTick();

  if (own !== session) return;

  // Next and Back stay where they are between steps, so a keyboard user who
  // pressed one keeps it; the card's live region announces the new step.
  // Focus that is anywhere else -- or on Back, which the first step drops --
  // goes to the card.
  const onButton =
    !!card.value?.contains(document.activeElement) &&
    document.activeElement !== card.value;

  if (!onButton) focusCard();
};

const next = () => {
  if (navigating.value) return;

  if (isLast.value) {
    end("finished");
  } else {
    void showStep(index.value + 1);
  }
};

const back = () => {
  if (navigating.value) return;

  if (!isFirst.value) void showStep(index.value - 1, -1);
};

const skip = () => end("skipped");

// The rest of the page is taken out of the tab order and the accessibility
// tree while the tour runs, so the card behaves like any modal dialog. A
// subtree marked `data-tour-keep` -- the notifications, which sit above the
// tour -- stays usable, so the walk descends around it instead of inerting
// the whole app root it lives in.
let inerted: Element[] = [];

const KEEP = "[data-tour-keep]";

const toInert = (element: Element): Element[] => {
  if (element === root.value || element.matches(KEEP)) return [];
  if (element.querySelector(KEEP)) return collectInert(element);
  return element.hasAttribute("inert") ? [] : [element];
};

const collectInert = (container: Element): Element[] =>
  Array.from(container.children).flatMap(toInert);

const makeInert = (elements: Element[]) => {
  elements.forEach((element) => element.setAttribute("inert", ""));
  inerted.push(...elements);
};

// A modal, a menu or a tooltip mounted while the tour runs lands next to the
// elements inerted at the start and would be reachable behind the dialog.
const lateMounts = new MutationObserver((mutations) => {
  mutations.forEach((mutation) => {
    const added = Array.from(mutation.addedNodes).filter(
      (node): node is Element => node instanceof Element,
    );
    makeInert(added.flatMap(toInert));
  });
});

const keptAncestors = (): Element[] => {
  const ancestors = new Set<Element>([document.body]);
  document.querySelectorAll(KEEP).forEach((kept) => {
    for (let node = kept.parentElement; node; node = node.parentElement) {
      ancestors.add(node);
    }
  });
  return Array.from(ancestors);
};

const setPageInert = (on: boolean) => {
  if (on) {
    inerted = [];
    makeInert(collectInert(document.body));
    keptAncestors().forEach((container) =>
      lateMounts.observe(container, { childList: true }),
    );
  } else {
    lateMounts.disconnect();
    inerted.forEach((element) => element.removeAttribute("inert"));
    inerted = [];
  }
};

const FOCUSABLE = "button:not([disabled]), a[href]";

const onKeydown = (event: KeyboardEvent) => {
  // Alt/Cmd+arrow is the browser's back and forward, and a notification left
  // usable keeps its own keys.
  if (event.altKey || event.metaKey || event.ctrlKey) return;

  const inTour =
    document.activeElement === document.body ||
    !!root.value?.contains(document.activeElement);
  if (!inTour) return;

  switch (event.key) {
    case "Escape":
      event.preventDefault();
      event.stopPropagation();
      if (isLast.value) {
        end("finished");
      } else {
        skip();
      }
      break;
    case "ArrowRight":
      event.preventDefault();
      next();
      break;
    case "ArrowLeft":
      event.preventDefault();
      back();
      break;
    case "Tab": {
      const focusable = Array.from(
        card.value?.querySelectorAll<HTMLElement>(FOCUSABLE) ?? [],
      );
      if (!focusable.length) return;

      const first = focusable[0];
      const last = focusable[focusable.length - 1];

      const onCard = document.activeElement === card.value;

      if (event.shiftKey && (onCard || document.activeElement === first)) {
        event.preventDefault();
        last.focus();
      } else if (
        !event.shiftKey &&
        (onCard || document.activeElement === last)
      ) {
        event.preventDefault();
        first.focus();
      }
      break;
    }
  }
};

let returnFocus: HTMLElement | null = null;

// Bumped by every start and every teardown. A start that resumes after its
// tour was closed or unmounted -- a navigation inside the render ticks it
// waits for -- must not make the next page inert with nothing left to undo it.
let session = 0;

// Whether the page is inert and focus has to be handed back.
let active = false;

// Content loading in or a filter row opening moves the target without a
// scroll or a resize of the window -- and inside a fixed or scrolling
// container without resizing the body either, so changes to the page's
// markup reposition as well. The tour's own updates are left out, or placing
// the card would schedule the next placement.
const observedPage = ref<HTMLElement | null>(null);

useResizeObserver(observedPage, schedulePlace);

const pageChanges = new MutationObserver((mutations) => {
  if (mutations.some((mutation) => !root.value?.contains(mutation.target))) {
    schedulePlace();
  }
});

// On the document rather than the card: focus can sit on <body> for a moment
// -- after a click on the backdrop, or before the first card is placed -- and
// the keys must still drive the tour.
const listen = () => {
  // Capture, so an Escape that ends the tour stops before the window-level
  // listeners of a confirm dialog react to it as well.
  document.addEventListener("keydown", onKeydown, true);
  window.addEventListener("scroll", schedulePlace, true);
  window.addEventListener("resize", schedulePlace);
  observedPage.value = document.body;
  pageChanges.observe(document.body, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ["class", "style", "hidden"],
  });
};

const unlisten = () => {
  document.removeEventListener("keydown", onKeydown, true);
  window.removeEventListener("scroll", schedulePlace, true);
  window.removeEventListener("resize", schedulePlace);
  observedPage.value = null;
  pageChanges.disconnect();
  window.cancelAnimationFrame(frame);
};

const start = async () => {
  session += 1;
  const own = session;

  index.value = 0;
  hole.value = null;
  cardPosition.value = null;
  passedOver.value = [];
  navigating.value = false;

  // A step on another page is looked for once the tour gets there.
  shownIds.value = props.steps
    .filter(
      (step) => !step.requiresTarget || isElsewhere(step) || !!findTarget(step),
    )
    .map((step) => step.id);

  // A modal open underneath would turn inert and unusable until the tour
  // ends, and a dialog over a dialog is no way to explain the page anyway.
  // `.in` rather than the bare class: a closing modal stays in the DOM for
  // its fade-out and would refuse a tour asked for right after it.
  if (!shown.value.length || document.querySelector(".app-modal.in")) {
    open.value = false;
    return;
  }

  // Focus on <body> is no place to return to; let the fallback take over.
  returnFocus =
    document.activeElement instanceof HTMLElement &&
    document.activeElement !== document.body
      ? document.activeElement
      : null;

  visible.value = true;

  await nextTick();

  if (own !== session) return;

  setPageInert(true);
  active = true;
  listen();
  emit("start");
  await showStep(0);
};

const teardown = ({ restoreFocus }: { restoreFocus: boolean }) => {
  session += 1;
  visible.value = false;
  navigating.value = false;
  unlisten();
  target = null;

  if (!active) return;

  active = false;
  setPageInert(false);

  if (!restoreFocus) {
    returnFocus = null;
    return;
  }

  // Nothing started it -- an automatic start -- so there is nothing to return
  // to, and the fallback would only drop focus on an arbitrary control.
  if (!returnFocus) return;

  const fallback = props.returnFocusFallback
    ? document.querySelector<HTMLElement>(props.returnFocusFallback)
    : null;
  const focusTo = [returnFocus, fallback].find(
    (element) => element?.isConnected && isRendered(element),
  );

  focusTo?.focus({ preventScroll: true });
  returnFocus = null;
};

function end(reason: TourEndReason) {
  open.value = false;
  emit("end", reason);
}

// The steps can change under a running tour -- a flag or the locale feeds
// them -- and a vanished step must not leave an inert page with no card. On
// the props rather than `shown`: passing over a step changes that list too,
// and `showStep` has already moved on by then.
watch(
  () => props.steps,
  () => {
    const steps = shown.value;

    // A step being navigated to is re-read from the props when it is shown.
    if (!visible.value || navigating.value) return;

    if (!steps.length) {
      end("finished");
    } else {
      // The same index can now name another step; re-show it either way, so
      // the spotlight, the card and the cached target follow.
      void showStep(Math.min(index.value, steps.length - 1));
    }
  },
);

watch(
  open,
  (value, previous) => {
    if (value) {
      void start();
    } else if (previous) {
      teardown({ restoreFocus: true });
    }
  },
  { immediate: true },
);

// Unmounted with the page it belonged to: whatever started it is leaving too.
onBeforeUnmount(() => teardown({ restoreFocus: false }));

const holeStyle = computed(() => {
  if (!hole.value) {
    return {
      top: "50%",
      left: "50%",
      width: "0px",
      height: "0px",
    };
  }

  return {
    top: `${hole.value.top}px`,
    left: `${hole.value.left}px`,
    width: `${hole.value.width}px`,
    height: `${hole.value.height}px`,
  };
});

const cardStyle = computed(() =>
  cardPosition.value
    ? {
        top: `${cardPosition.value.top}px`,
        left: `${cardPosition.value.left}px`,
      }
    : { visibility: "hidden" as const },
);
</script>

<template>
  <Teleport to="body">
    <div
      v-if="visible && current"
      ref="root"
      class="tour"
      :class="{ 'tour--animated': !prefersReducedMotion }"
      data-test="tour"
    >
      <div class="tour__backdrop" @click="focusCard" />
      <div
        class="tour__hole"
        :class="{ 'tour__hole--empty': !hole }"
        :style="holeStyle"
        aria-hidden="true"
      />
      <div
        ref="card"
        class="tour__card"
        :style="cardStyle"
        role="dialog"
        aria-modal="true"
        :aria-labelledby="titleId"
        :aria-describedby="textId"
        tabindex="-1"
        :data-step="current.id"
        data-test="tour-card"
      >
        <p class="tour__counter">
          {{
            t("labels.tour.step", {
              current: index + 1,
              total: shown.length,
            })
          }}
        </p>
        <div aria-live="polite">
          <h2 :id="titleId" class="tour__title">{{ current.title }}</h2>
          <p :id="textId" class="tour__text">{{ current.text }}</p>
        </div>
        <div class="tour__actions">
          <Btn
            v-if="!isLast"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            data-test="tour-skip"
            @click="skip"
          >
            {{ t("actions.tour.skip") }}
          </Btn>
          <span class="tour__spacer" />
          <Btn
            v-if="!isFirst"
            :size="BtnSizesEnum.SM"
            data-test="tour-back"
            @click="back"
          >
            {{ t("actions.tour.back") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.SOLID"
            data-test="tour-next"
            @click="next"
          >
            {{ isLast ? t("actions.tour.done") : t("actions.tour.next") }}
          </Btn>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
