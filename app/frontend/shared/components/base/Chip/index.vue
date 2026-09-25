<script lang="ts">
export default {
  name: "BaseChip",
};
</script>

<script lang="ts" setup>
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  state?: `${ChipStatesEnum}`;
  /** Group colour, drawn as a leading dot. Replaced by the state icon once the
   *  chip is included or excluded, so the two never compete for the same slot. */
  dot?: string;
  count?: number;
  disabled?: boolean;
  /** Renders a secondary action button inside the frame and emits `edit`. */
  editable?: boolean;
  editLabel?: string;
  /**
   * Draws a leading grip. The consumer binds its drag to `.chip__handle` rather
   * than the whole chip: a toggle that is also a drag target cannot be clicked
   * without moving it a little first. The grip is focusable and emits `move`
   * on the arrow keys, which is the keyboard route to the same reorder.
   */
  sortable?: boolean;
  sortLabel?: string;
  /**
   * Content only - no frame, no button, no interaction. For a chip's contents
   * inside a control that is already interactive, which is what the mobile
   * dropdown items need: a button may not be nested inside a button.
   */
  bare?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  state: ChipStatesEnum.NEUTRAL,
  dot: undefined,
  count: undefined,
  disabled: false,
  editable: false,
  editLabel: undefined,
  sortable: false,
  sortLabel: undefined,
  bare: false,
});

const emit = defineEmits<{
  toggle: [];
  edit: [];
  move: [offset: -1 | 1];
}>();

const MOVE_KEYS: Record<string, -1 | 1> = {
  ArrowLeft: -1,
  ArrowUp: -1,
  ArrowRight: 1,
  ArrowDown: 1,
};

// Enter and Space are swallowed, not acted on: the grip has no single action to
// activate, and Space would otherwise scroll the page. What it does instead is
// announced through the sort hint.
const onHandleKeydown = (event: KeyboardEvent) => {
  if (event.key === "Enter" || event.key === " ") {
    event.preventDefault();
    return;
  }

  const offset = MOVE_KEYS[event.key];
  if (!offset) return;

  event.preventDefault();
  emit("move", offset);
};

const sortHintId = useId();

const { t } = useI18n();

const cssClasses = computed(() => ({
  [`chip--${props.state}`]: props.state !== ChipStatesEnum.NEUTRAL,
  "chip--disabled": props.disabled,
  "chip--bare": props.bare,
  "chip--sortable": props.sortable && !props.bare,
  "chip--editable": props.editable && !props.bare,
}));

const toggleProps = computed(() => {
  if (props.bare) return {};

  return {
    type: "button",
    disabled: props.disabled,
    "aria-pressed": props.state === ChipStatesEnum.INCLUDED,
  };
});

const toggle = () => {
  if (props.bare) return;

  emit("toggle");
};

const stateIcon = computed(() => {
  if (props.state === ChipStatesEnum.INCLUDED) return "fa-regular fa-check";
  if (props.state === ChipStatesEnum.EXCLUDED) return "fa-regular fa-minus";

  return undefined;
});

// The state is carried by an icon *and* a colour, so "excluded" is not signalled
// by colour alone - and appended to the accessible name, because aria-pressed has
// no third value to express exclusion with.
const stateHint = computed(() => {
  if (props.state === ChipStatesEnum.INCLUDED) {
    return t("baseChip.states.included");
  }
  if (props.state === ChipStatesEnum.EXCLUDED) {
    return t("baseChip.states.excluded");
  }

  return undefined;
});
</script>

<template>
  <span
    class="chip"
    :class="cssClasses"
    :style="dot ? { '--chip-dot': dot } : undefined"
    data-test="chip"
  >
    <!-- A span, not a button: Firefox starts no native drag from inside a
         button, and the drag is what this control is mostly for. -->
    <span
      v-if="sortable && !bare"
      v-tooltip="sortLabel"
      class="chip__handle"
      role="button"
      tabindex="0"
      :aria-label="sortLabel"
      :aria-describedby="sortHintId"
      data-test="chip-handle"
      @keydown="onHandleKeydown"
    >
      <i class="fa-regular fa-grip-vertical" />
      <span :id="sortHintId" class="chip__state">
        {{ t("baseChip.sortHint") }}
      </span>
    </span>
    <component
      :is="bare ? 'span' : 'button'"
      class="chip__toggle"
      v-bind="toggleProps"
      @click="toggle"
    >
      <i v-if="stateIcon" :class="stateIcon" class="chip__icon" />
      <span v-else-if="dot" class="chip__dot" />
      <span class="chip__label"><slot /></span>
      <span v-if="count !== undefined" class="chip__count">{{ count }}</span>
      <span v-if="stateHint" class="chip__state">{{ stateHint }}</span>
    </component>
    <button
      v-if="editable && !bare"
      v-tooltip="editLabel"
      type="button"
      class="chip__action"
      :aria-label="editLabel"
      data-test="chip-edit"
      @click="emit('edit')"
    >
      <i class="fa-regular fa-pen" />
    </button>
  </span>
</template>

<!--
  Plain CSS, not lang="scss", for the reason Btn documents: sass preprocesses the
  block first and @apply/@reference reach the minifier as unknown at-rules.
-->
<style scoped>
@reference "../../../../entrypoints/tailwind.css";

/*
 * One box. The stylesheet this replaces (partials/labels.scss) wrapped a 2px
 * $panel-inner-border box around a second, inner box and drew a pair of #444
 * hairlines between them - both values the panel and button redesigns retired.
 *
 * No end-caps. That is the same call `.panel--slim` makes: a wrapping row of a
 * dozen chips is a denser repetition than any card grid, and at chip width a cap
 * inset 12% per side is a third of the element. The cap stays the signature of a
 * surface - panel, band, dropdown - rather than of everything clickable.
 *
 * The frame is on the wrapper rather than the button because `editable` adds a
 * second control, and a button cannot be nested inside a button.
 */
.chip {
  @apply relative inline-flex items-stretch;
  @apply bg-control border-edge-soft text-text rounded-control-bare border;
  @apply transition-[background-color,border-color,color] duration-150 ease-in-out;
}

.chip:hover:not(.chip--disabled) {
  @apply bg-control-hover text-lifted;
}

.chip__toggle {
  @apply inline-flex cursor-pointer items-center gap-2;
  @apply m-0 border-0 bg-transparent text-[15px] leading-none text-inherit;
  padding: 6px 10px;
}

/* Inside the frame, so the ring does not straddle the border. */
.chip__toggle:focus-visible,
.chip__handle:focus-visible,
.chip__action:focus-visible {
  @apply outline-primary rounded-control-bare outline-2;
  outline-offset: -2px;
}

.chip__label {
  @apply whitespace-nowrap;
}

.chip__count {
  @apply opacity-70;
  font-variant-numeric: tabular-nums;
}

.chip__dot {
  @apply inline-block h-[10px] w-[10px] shrink-0 rounded-full;
  /* Data, passed as a custom property by the consumer, so a group's colour never
     needs a nested inline-styled element. */
  background-color: var(--chip-dot, transparent);
}

.chip__icon {
  @apply w-[10px] shrink-0 text-[11px] leading-none;
}

/* Announced, never shown: the visible signal is the icon plus the tint. */
.chip__state {
  @apply sr-only;
}

/* ---------- states ----------
   Alphas are base/Pill's .2/.4, one step up for the darker --color-control
   ground. The label keeps --color-text in every state: the stylesheet this
   replaces flipped it to invert($text-color) - #373737 on a near-white fill -
   which was louder than any other control in the app and left an active chip
   with no hover feedback, since hover and active were the same declaration. */
.chip--included {
  background-color: color-mix(
    in srgb,
    var(--color-primary, #428bca) 22%,
    transparent
  );
  border-color: color-mix(
    in srgb,
    var(--color-primary, #428bca) 50%,
    transparent
  );
}

.chip--included:hover {
  background-color: color-mix(
    in srgb,
    var(--color-primary, #428bca) 32%,
    transparent
  );
}

.chip--excluded {
  background-color: rgb(220 53 69 / 0.22);
  border-color: rgb(220 53 69 / 0.5);
}

.chip--excluded:hover {
  background-color: rgb(220 53 69 / 0.32);
}

.chip--disabled .chip__toggle {
  @apply cursor-default opacity-45;
}

/* Content only. Keeps the dot, the state icon and the count metrics so a chip
   rendered inside another control matches the ones in the row beside it. */
.chip--bare,
.chip--bare:hover {
  @apply border-transparent bg-transparent text-inherit;
}

.chip--bare .chip__toggle {
  @apply p-0;
  cursor: inherit;
}

/* ---------- edit mode ----------
   Grip and edit action are rendered only while the consumer is in an edit mode,
   and are fully shown when they are: a control that is hidden but still
   reserved leaves every chip in the row padded with an empty slot.
   The grip takes glyph grey, not text grey - it is a mark, not a label. */
.chip__handle {
  @apply flex shrink-0 cursor-grab items-center text-[13px] leading-none;
  color: var(--color-muted, #7a8288);
  padding: 0 0 0 9px;
  transition: color 150ms ease-in-out;
}

.chip__handle:active {
  @apply cursor-grabbing;
}

.chip:hover .chip__handle {
  color: var(--color-text-dim, #959595);
}

/* Qualified by .chip so it outranks the chip-hover rule above. */
.chip .chip__handle:hover,
.chip .chip__handle:focus-visible {
  @apply text-lifted;
}

.chip--sortable .chip__toggle {
  padding-left: 7px;
}

/* A segment of its own - a hairline divider and its own fill on hover - so it is
   plain which part of the chip filters and which part edits. */
.chip__action {
  @apply flex cursor-pointer items-center;
  @apply m-0 border-0 bg-transparent text-[12px] text-inherit;
  @apply transition-[opacity,background-color] duration-150 ease-in-out;
  border-top-right-radius: inherit;
  border-bottom-right-radius: inherit;
  box-shadow: inset 1px 0 0 var(--color-edge-soft);
  opacity: 0.7;
  padding: 0 9px;
}

.chip .chip__action:hover,
.chip__action:focus-visible {
  opacity: 1;
  background-color: color-mix(in srgb, currentColor 10%, transparent);
}

.chip--editable .chip__toggle {
  padding-right: 8px;
}

/* ---------- drag ----------
   The placeholder where the chip will land. Dashed rather than filled, so it
   reads as a slot and not as a second copy of the chip being dragged. */
.chip--ghost,
.chip--ghost:hover {
  border-style: dashed;
  border-color: color-mix(
    in srgb,
    var(--color-primary, #428bca) 70%,
    transparent
  );
  /* Mixed into the control fill rather than into transparent: the row sits on
     the page backdrop, which would show through an empty slot. */
  background-color: color-mix(
    in srgb,
    var(--color-primary, #428bca) 12%,
    var(--color-control)
  );
}

.chip--ghost > * {
  opacity: 0.35;
}

@media (prefers-reduced-motion: reduce) {
  .chip,
  .chip__handle,
  .chip__action {
    transition-duration: 1ms;
  }
}
</style>
