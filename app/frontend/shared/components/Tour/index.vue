<script lang="ts">
export default {
  name: "AppTour",
};
</script>

<script lang="ts" setup>
import { useResizeObserver } from "@vueuse/core";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";
import { placeFloating } from "@/shared/utils/floatingPlacement";
import type { TourEndReason, TourStep } from "./types";

type Props = {
  steps: TourStep[];
  // Where focus goes when the element that started the tour is gone or hidden
  // by then -- an item in a dropdown menu that closed when it was picked.
  returnFocusFallback?: string;
};

const props = withDefaults(defineProps<Props>(), {
  returnFocusFallback: undefined,
});

const open = defineModel<boolean>("open", { default: false });

const emit = defineEmits<{ end: [reason: TourEndReason] }>();

const { t } = useI18n();

const { prefersReducedMotion } = useReducedMotion();

const HOLE_PADDING = 6;
const GAP = 12;
const MARGIN = 12;

const titleId = useId();
const textId = useId();

const root = ref<HTMLElement | null>(null);
const card = ref<HTMLElement | null>(null);

const shown = ref<TourStep[]>([]);
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

const findTarget = (step?: TourStep): HTMLElement | null => {
  if (!step?.target) return null;

  return (
    Array.from(document.querySelectorAll<HTMLElement>(step.target)).find(
      isRendered,
    ) ?? null
  );
};

const inViewport = (rect: DOMRect) =>
  rect.top >= 0 &&
  rect.left >= 0 &&
  rect.bottom <= window.innerHeight &&
  rect.right <= window.innerWidth;

const place = () => {
  const target = findTarget(current.value);

  if (target) {
    const rect = target.getBoundingClientRect();
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

const showStep = async (next: number) => {
  index.value = next;

  await nextTick();

  if (!open.value) return;

  const target = findTarget(current.value);

  if (target && !inViewport(target.getBoundingClientRect())) {
    target.scrollIntoView({
      block: "center",
      inline: "nearest",
      behavior: prefersReducedMotion.value ? "auto" : "smooth",
    });
  }

  place();
  focusCard();
};

const next = () => {
  if (isLast.value) {
    end("finished");
  } else {
    void showStep(index.value + 1);
  }
};

const back = () => {
  if (!isFirst.value) void showStep(index.value - 1);
};

const skip = () => end("skipped");

// The rest of the page is taken out of the tab order and the accessibility
// tree while the tour runs, so the card behaves like any modal dialog.
let inerted: Element[] = [];

const setPageInert = (on: boolean) => {
  if (on) {
    inerted = Array.from(document.body.children).filter(
      (element) => element !== root.value && !element.hasAttribute("inert"),
    );
    inerted.forEach((element) => element.setAttribute("inert", ""));
  } else {
    inerted.forEach((element) => element.removeAttribute("inert"));
    inerted = [];
  }
};

const FOCUSABLE = "button:not([disabled]), a[href]";

const onKeydown = (event: KeyboardEvent) => {
  switch (event.key) {
    case "Escape":
      event.preventDefault();
      skip();
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

// Content loading in or a filter row opening moves the target without a
// scroll or a resize of the window.
const observedPage = ref<HTMLElement | null>(null);

useResizeObserver(observedPage, schedulePlace);

const listen = () => {
  window.addEventListener("scroll", schedulePlace, true);
  window.addEventListener("resize", schedulePlace);
  observedPage.value = document.body;
};

const unlisten = () => {
  window.removeEventListener("scroll", schedulePlace, true);
  window.removeEventListener("resize", schedulePlace);
  observedPage.value = null;
  window.cancelAnimationFrame(frame);
};

const start = async () => {
  session += 1;
  const own = session;

  index.value = 0;
  hole.value = null;
  cardPosition.value = null;

  shown.value = props.steps.filter(
    (step) => !step.requiresTarget || !!findTarget(step),
  );

  if (!shown.value.length) {
    open.value = false;
    return;
  }

  returnFocus =
    document.activeElement instanceof HTMLElement
      ? document.activeElement
      : null;

  await nextTick();

  if (own !== session) return;

  setPageInert(true);
  listen();
  await showStep(0);
};

const teardown = () => {
  session += 1;
  unlisten();
  setPageInert(false);

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

watch(
  open,
  (value, previous) => {
    if (value) {
      void start();
    } else if (previous) {
      teardown();
    }
  },
  { immediate: true },
);

onBeforeUnmount(teardown);

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
      v-if="open && current"
      ref="root"
      class="tour"
      :class="{ 'tour--animated': !prefersReducedMotion }"
      data-test="tour"
      @keydown="onKeydown"
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
        <h2 :id="titleId" class="tour__title">{{ current.title }}</h2>
        <p :id="textId" class="tour__text">{{ current.text }}</p>
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
