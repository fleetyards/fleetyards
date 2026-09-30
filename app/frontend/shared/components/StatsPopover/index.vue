<script lang="ts">
export default {
  name: "StatsPopover",
  // Two roots -- the trigger and the teleported card -- so attributes are
  // bound to the trigger by hand.
  inheritAttrs: false,
};
</script>

<script lang="ts" setup>
import { useResizeObserver } from "@vueuse/core";
import { claimActive, releaseActive } from "./activePopover";
import { type StatsPopoverPlacement, type StatsPopoverTrigger } from "./types";

type Props = {
  // Names the card for assistive tech: it is a dialog, and the trigger it
  // hangs off is usually a link whose text is the same name.
  label: string;
  placement?: StatsPopoverPlacement;
  disabled?: boolean;
  openDelay?: number;
  closeDelay?: number;
};

const props = withDefaults(defineProps<Props>(), {
  placement: "bottom",
  disabled: false,
  openDelay: 300,
  closeDelay: 150,
});

const emit = defineEmits<{ open: []; close: [] }>();

const GAP = 8;
const MARGIN = 8;

const id = useId();

const trigger = ref<HTMLElement | null>(null);
const panel = ref<HTMLElement | null>(null);

const open = ref(false);
const openedBy = ref<StatsPopoverTrigger>("hover");
const placed = ref<StatsPopoverPlacement>(props.placement);
const position = ref({ top: 0, left: 0 });

// Plain text has nothing to focus, so the keyboard could never reach its card.
const ownTabindex = ref<number | undefined>(undefined);

let openTimer = 0;
let closeTimer = 0;

/*
 * Which pointer last arrived over the trigger: "mouse", "touch", "pen", or ""
 * where the browser reports no pointer events. Read from `pointerover` because
 * it is the one ordering the Pointer Events spec pins down -- the compatibility
 * mouse events a tap fires always come after it, while `pointerdown` lands on
 * either side of the synthetic `mouseenter` depending on the browser build.
 *
 * `(hover: none)` cannot answer this: it describes the primary pointer only, so
 * a touchscreen laptop would send every finger tap down the mouse path.
 */
let pointerType = "";

const tapDriven = () => pointerType !== "" && pointerType !== "mouse";

const clearTimers = () => {
  window.clearTimeout(openTimer);
  window.clearTimeout(closeTimer);
  openTimer = 0;
  closeTimer = 0;
};

const focusTarget = () =>
  trigger.value?.querySelector<HTMLElement>(
    "a[href], button, [tabindex]:not([tabindex='-1'])",
  ) ?? trigger.value;

const place = () => {
  if (!trigger.value || !panel.value) return;

  const anchor = trigger.value.getBoundingClientRect();
  const box = panel.value.getBoundingClientRect();

  const below = window.innerHeight - anchor.bottom - GAP - MARGIN;
  const above = anchor.top - GAP - MARGIN;

  let side = props.placement;
  if (side === "bottom" && box.height > below && above > below) side = "top";
  if (side === "top" && box.height > above && below > above) side = "bottom";

  const top =
    side === "bottom" ? anchor.bottom + GAP : anchor.top - box.height - GAP;
  const left = anchor.left + anchor.width / 2 - box.width / 2;

  placed.value = side;
  position.value = {
    top: Math.max(
      MARGIN,
      Math.min(top, window.innerHeight - box.height - MARGIN),
    ),
    left: Math.max(
      MARGIN,
      Math.min(left, window.innerWidth - box.width - MARGIN),
    ),
  };
};

// A lazily loaded card changes size once its data arrives.
useResizeObserver(panel, () => {
  if (open.value) place();
});

const within = (node: EventTarget | null) =>
  node instanceof Node &&
  (!!trigger.value?.contains(node) || !!panel.value?.contains(node));

const onDocumentPointerdown = (event: PointerEvent) => {
  if (!within(event.target)) close();
};

const onDocumentKeydown = (event: KeyboardEvent) => {
  if (event.key !== "Escape") return;

  const hadFocus = within(document.activeElement);
  close();

  if (hadFocus) focusTarget()?.focus({ preventScroll: true });
};

// A tap-opened card has nothing to follow the page with, and one left floating
// over content the finger has scrolled past reads as stuck. A hovered one
// follows its trigger instead, since the pointer is still on it.
const onWindowScroll = (event: Event) => {
  if (within(event.target)) return;

  if (openedBy.value === "tap") {
    close();
  } else {
    place();
  }
};

const onWindowResize = () => place();

const listen = () => {
  document.addEventListener("pointerdown", onDocumentPointerdown, true);
  document.addEventListener("keydown", onDocumentKeydown, true);
  window.addEventListener("scroll", onWindowScroll, true);
  window.addEventListener("resize", onWindowResize);
};

const unlisten = () => {
  document.removeEventListener("pointerdown", onDocumentPointerdown, true);
  document.removeEventListener("keydown", onDocumentKeydown, true);
  window.removeEventListener("scroll", onWindowScroll, true);
  window.removeEventListener("resize", onWindowResize);
};

const setDescribedBy = (on: boolean) => {
  const target = focusTarget();
  if (!target) return;

  if (on) {
    target.setAttribute("aria-describedby", id);
  } else if (target.getAttribute("aria-describedby") === id) {
    target.removeAttribute("aria-describedby");
  }
};

function close() {
  clearTimers();
  if (!open.value) return;

  open.value = false;
  releaseActive(close);
  unlisten();
  setDescribedBy(false);
  emit("close");
}

const show = async (by: StatsPopoverTrigger) => {
  clearTimers();
  if (props.disabled || !trigger.value?.isConnected) return;

  openedBy.value = by;
  if (open.value) return;

  claimActive(close);
  open.value = true;
  listen();
  setDescribedBy(true);
  emit("open");

  await nextTick();
  place();
};

const scheduleOpen = () => {
  window.clearTimeout(closeTimer);
  closeTimer = 0;
  if (open.value || openTimer) return;

  openTimer = window.setTimeout(() => {
    openTimer = 0;
    void show("hover");
  }, props.openDelay);
};

// The grace period is what lets the pointer cross the gap into the card.
const scheduleClose = () => {
  window.clearTimeout(openTimer);
  openTimer = 0;
  if (!open.value || closeTimer) return;

  closeTimer = window.setTimeout(() => {
    closeTimer = 0;
    close();
  }, props.closeDelay);
};

const onPointerover = (event: PointerEvent) => {
  pointerType = event.pointerType || "";
};

const onMouseenter = () => {
  if (tapDriven()) return;

  scheduleOpen();
};

const onMouseleave = () => {
  if (tapDriven() || openedBy.value !== "hover") return;

  scheduleClose();
};

/*
 * On touch the first tap shows the card and goes no further, even when the
 * trigger is a link: following it would make the card unreachable on a phone,
 * and the card carries the same link. A second tap then does what the trigger
 * does. `detail` is the click count, which a keyboard activation does not have,
 * so Enter on a link still follows it.
 */
const onClickCapture = (event: MouseEvent) => {
  if (props.disabled || event.detail === 0) return;

  if (!tapDriven()) {
    close();
    return;
  }

  if (open.value) {
    close();
    return;
  }

  event.preventDefault();
  event.stopPropagation();
  void show("tap");
};

// Keyboard only. Pointer focus already has hover, and showing a card on every
// focus would also pop one up when focus is restored after a modal closes.
const onFocusin = (event: FocusEvent) => {
  const target = event.target as HTMLElement | null;

  try {
    if (!target?.matches(":focus-visible")) return;
  } catch {
    // Browsers without :focus-visible fall through and show it.
  }

  void show("focus");
};

const onFocusout = (event: FocusEvent) => {
  if (within(event.relatedTarget)) return;
  if (openedBy.value === "focus") close();
};

const onPanelMouseenter = () => {
  window.clearTimeout(closeTimer);
  closeTimer = 0;
};

const onPanelMouseleave = () => {
  if (openedBy.value === "hover") scheduleClose();
};

watch(
  () => props.disabled,
  (disabled) => {
    if (disabled) close();
  },
);

onMounted(() => {
  if (!trigger.value?.querySelector("a[href], button, [tabindex]")) {
    ownTabindex.value = 0;
  }
});

onBeforeUnmount(() => {
  close();
  clearTimers();
});

defineExpose({ open, show, close });
</script>

<template>
  <span
    v-bind="$attrs"
    ref="trigger"
    class="stats-popover__trigger"
    :class="{ 'stats-popover__trigger--open': open }"
    :tabindex="ownTabindex"
    aria-haspopup="dialog"
    :aria-expanded="open"
    :aria-controls="open ? id : undefined"
    data-test="stats-popover-trigger"
    @pointerover="onPointerover"
    @mouseenter="onMouseenter"
    @mouseleave="onMouseleave"
    @click.capture="onClickCapture"
    @focusin="onFocusin"
    @focusout="onFocusout"
  >
    <slot />
  </span>

  <Teleport to="body">
    <div
      v-if="open"
      :id="id"
      ref="panel"
      class="stats-popover"
      :class="`stats-popover--${placed}`"
      :style="{ top: `${position.top}px`, left: `${position.left}px` }"
      role="dialog"
      :aria-label="label"
      data-test="stats-popover"
      @mouseenter="onPanelMouseenter"
      @mouseleave="onPanelMouseleave"
      @focusout="onFocusout"
    >
      <slot name="content" :close="close" />
    </div>
  </Teleport>
</template>

<!-- Plain CSS, not scss: see the note in base/Btn/index.vue. -->
<style scoped>
@reference "../../../entrypoints/tailwind.css";

.stats-popover__trigger {
  display: inline;
}

.stats-popover__trigger[tabindex] {
  cursor: help;
}

/*
 * The dropdown menu's material and layer: opaque, because it floats over
 * arbitrary content, and at 2100 so a row inside a modal (1050) can still open
 * one above it.
 */
.stats-popover {
  @apply bg-gray-darker border-edge rounded-control border;
  position: fixed;
  z-index: 2100;
  width: max-content;
  max-width: min(340px, calc(100vw - 16px));
  max-height: calc(100vh - 16px);
  overflow-y: auto;
  box-shadow: 0 8px 24px rgb(0 0 0 / 0.45);
  font-size: 1rem;
}
</style>
