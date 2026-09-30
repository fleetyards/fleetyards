<script lang="ts">
export default {
  name: "BasePopover",
  // Two roots -- the trigger and the teleported card -- so attributes are
  // bound to the trigger by hand.
  inheritAttrs: false,
};
</script>

<script lang="ts" setup>
import { useResizeObserver } from "@vueuse/core";
import { placeFloating } from "@/shared/utils/floatingPlacement";
import { claimActive, releaseActive } from "./activePopover";
import { popoverLayerKey, POPOVER_BASE_LAYER } from "./layer";
import { type PopoverPlacement, type PopoverTrigger } from "./types";

type Props = {
  // Names the card for assistive tech: it is a dialog, and the trigger it
  // hangs off is usually a link whose text is the same name.
  label: string;
  placement?: PopoverPlacement;
  disabled?: boolean;
  openDelay?: number;
  closeDelay?: number;
  // Off where the trigger sits inside a link of its own -- a list row's name --
  // since a focus stop inside an anchor is one the keyboard lands on twice.
  focusable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  placement: "bottom",
  disabled: false,
  openDelay: 300,
  closeDelay: 150,
  focusable: true,
});

const emit = defineEmits<{ open: []; close: [] }>();

const GAP = 8;
const MARGIN = 8;

const id = useId();

const trigger = ref<HTMLElement | null>(null);
const panel = ref<HTMLElement | null>(null);

const open = ref(false);
const openedBy = ref<PopoverTrigger>("hover");
const placed = ref<PopoverPlacement>(props.placement);
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

const FOCUSABLE = "a[href], button, [tabindex]:not([tabindex='-1'])";

/*
 * A trigger inside a control it does not own -- a list row's name, where the
 * row's link wraps it -- cannot take focus itself without nesting one focus
 * stop in another. That control drives the card instead: its focus opens it
 * and it carries the description. Focus events bubble up, never down, so it is
 * listened to directly.
 */
const host = ref<HTMLElement | null>(null);

const focusTarget = () =>
  trigger.value?.querySelector<HTMLElement>(FOCUSABLE) ??
  host.value ??
  trigger.value;

const place = () => {
  if (!trigger.value || !panel.value) return;

  const { top, left, placement } = placeFloating(
    trigger.value.getBoundingClientRect(),
    panel.value.getBoundingClientRect(),
    props.placement,
    { gap: GAP, margin: MARGIN, flip: true },
  );

  placed.value = placement === "top" ? "top" : "bottom";
  position.value = { top, left };
};

// A card opened from inside a modal belongs above that modal; anywhere else it
// sits above the page and below any modal that opens over it.
const layer = inject(popoverLayerKey, undefined);
const zIndex = computed(() =>
  layer === undefined ? POPOVER_BASE_LAYER : layer + 1,
);

// A lazily loaded card changes size once its data arrives.
useResizeObserver(panel, () => {
  if (open.value) place();
});

const within = (node: EventTarget | null) =>
  node instanceof Node &&
  (!!trigger.value?.contains(node) ||
    !!host.value?.contains(node) ||
    !!panel.value?.contains(node));

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

const show = async (by: PopoverTrigger) => {
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
 * and the card carries the same link. A second tap closes it and does what the
 * trigger does -- a link still navigates. Neither tap reaches a click handler
 * around the trigger, such as a hardpoint row that toggles its stack: the
 * trigger is the popover's, and a row that expands under a closing card reads
 * as the tap having done two things. `detail` is the click count, which a
 * keyboard activation does not have, so Enter on a link still follows it.
 */
const onClickCapture = (event: MouseEvent) => {
  if (props.disabled || event.detail === 0) return;

  if (!tapDriven()) {
    close();
    return;
  }

  event.stopPropagation();

  if (open.value) {
    close();
    return;
  }

  event.preventDefault();
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
  if (!trigger.value || trigger.value.querySelector(FOCUSABLE)) return;

  const enclosing =
    trigger.value.parentElement?.closest<HTMLElement>(FOCUSABLE);

  if (enclosing) {
    host.value = enclosing;
    enclosing.addEventListener("focusin", onFocusin);
    enclosing.addEventListener("focusout", onFocusout);
  } else if (props.focusable) {
    ownTabindex.value = 0;
  }
});

onBeforeUnmount(() => {
  host.value?.removeEventListener("focusin", onFocusin);
  host.value?.removeEventListener("focusout", onFocusout);
  close();
  clearTimers();
});

defineExpose({ open, show, close });
</script>

<template>
  <span
    v-bind="$attrs"
    ref="trigger"
    class="popover__trigger"
    :class="{ 'popover__trigger--open': open }"
    :tabindex="ownTabindex"
    aria-haspopup="dialog"
    :aria-expanded="open"
    :aria-controls="open ? id : undefined"
    data-test="popover-trigger"
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
      class="popover"
      :class="`popover--${placed}`"
      :style="{
        top: `${position.top}px`,
        left: `${position.left}px`,
        zIndex,
      }"
      role="dialog"
      :aria-label="label"
      data-test="popover"
      @mouseenter="onPanelMouseenter"
      @mouseleave="onPanelMouseleave"
      @focusout="onFocusout"
    >
      <slot name="content" :close="close" />
    </div>
  </Teleport>
</template>

<style lang="scss" scoped>
@import "index";
</style>
