<script lang="ts">
export default {
  name: "BaseBtnGroup",
};
</script>

<script lang="ts" setup>
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import type { BtnSizesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  /** Set once here instead of on every member. */
  size?: `${BtnSizesEnum}`;
  block?: boolean;
  /**
   * A switch rather than a row of actions: the track recesses, one thumb slides
   * to the chosen segment, and members take radio semantics. Use it wherever a
   * group selects between modes; leave it off for grouped actions.
   */
  segmented?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: undefined,
  block: false,
  segmented: false,
});

// Members report themselves in mount order, which is DOM order, so the thumb can
// be placed without this component reading a member's index or state out of the
// DOM. Shallow refs of getters rather than values: a member's `active` changes
// after registration and the thumb has to follow.
const members = ref<Array<() => boolean>>([]);

const register = (active: () => boolean) => {
  members.value = [...members.value, active];

  return {
    unregister: () => {
      members.value = members.value.filter((entry) => entry !== active);
    },
  };
};

const segmentCount = computed(() => members.value.length || 1);

/*
 * `segmented` means one-of-n. A group of independent toggles - HoloViewer's
 * auto-rotate, zoom and colour, which can all be on at once - is a toolbar, and
 * the thumb would park under whichever happened to be first and misreport the
 * rest. Not detectable from markup, so say so out loud in development.
 */
if (import.meta.env.DEV) {
  watchEffect(() => {
    if (!props.segmented) {
      return;
    }

    const active = members.value.filter((isActive) => isActive()).length;

    if (active > 1) {
      console.warn(
        `[BtnGroup] segmented expects one active member, found ${active}. ` +
          "Independent toggles want a plain group, not a switch.",
      );
    }
  });
}

// -1 while nothing is chosen, which parks the thumb off the first segment rather
// than under it - a switch with no selection should not claim one.
const activeIndex = computed(() =>
  members.value.findIndex((isActive) => isActive()),
);

// Members read this and drop their own border, radius and end-caps, so this
// component never needs descendant selectors into Btn's internals. The previous
// version carried 118 lines of `> :deep(.panel-btn)` overrides with !important.
provide(BTN_CONTAINER, {
  container: "group",
  size: computed(() => props.size),
  block: computed(() => props.block),
  segmented: computed(() => props.segmented),
  register,
});
</script>

<template>
  <div
    class="btn-group"
    :class="{
      'btn-group--block': block,
      'btn-group--segmented': segmented,
    }"
    :role="segmented ? 'radiogroup' : 'group'"
    :style="
      segmented
        ? { '--seg-count': segmentCount, '--seg-index': activeIndex }
        : undefined
    "
  >
    <div class="btn-group__track">
      <!-- One element that moves, rather than a fill appearing elsewhere: the
           slide is what tells you what changed, not just what is chosen. -->
      <span
        v-if="segmented && activeIndex >= 0"
        class="btn-group__thumb"
        aria-hidden="true"
      />
      <slot />
    </div>
  </div>
</template>

<!-- Plain CSS, not scss: see the note in Btn/index.vue. -->
<style scoped>
@reference "../../../../entrypoints/tailwind.css";

/*
 * The metrics-card__hero pattern: the container owns the border and radius, and
 * the 1px gap lets the container background read as hairline dividers between
 * members. Members are flat fills with no chrome of their own.
 */
.btn-group {
  @apply relative inline-flex;
  @apply border-edge rounded-control border;
  margin: 0;
}

/*
 * The track clips member corners so no member needs to know its position in the
 * group. Relying on :first-child/:last-child instead would break the moment a
 * member is wrapped in another component - a BtnDropdown trigger is the first
 * *and* last child of its own wrapper, so it took a radius on both sides.
 *
 * The clipping lives here rather than on .btn-group because the group's end-caps
 * sit outside its border and overflow:hidden would crop them.
 */
.btn-group__track {
  @apply bg-edge-soft flex items-stretch overflow-hidden;
  gap: 1px;
  width: 100%;
  border-radius: var(--radius-control-inner, 7px);
}

/*
 * One pair of end-caps for the whole control, rather than a pair per member -
 * per-member caps stack hairlines through the middle of the group. This is also
 * why the container cannot use overflow:hidden to clip member corners: it would
 * crop these caps, which sit on the border. Members radius their own end
 * corners instead.
 */
.btn-group::before,
.btn-group::after {
  content: "";
  position: absolute;
  left: max(10px, var(--cap-inset, 12%));
  right: max(10px, var(--cap-inset, 12%));
  height: var(--cap-h-btn, 2px);
  z-index: 2;
  @apply bg-endcap;
}

.btn-group::before {
  top: -1px;
  border-radius: 0 0 var(--cap-r-btn, 1px) var(--cap-r-btn, 1px);
}

.btn-group::after {
  bottom: -1px;
  border-radius: var(--cap-r-btn, 1px) var(--cap-r-btn, 1px) 0 0;
}

/* ---------- segmented ----------
 * A recessed well holding a switch, rather than buttons touching. The track goes
 * a step below the control fill so the thumb - which *is* the control fill - reads
 * as sitting in it, and hover is left free to mean hover.
 */
.btn-group--segmented {
  @apply bg-control-press border-edge-soft;
  padding: 3px;
}

/*
 * Grid, not flex. `flex: 1 1 0` on the members gives them a zero basis, so they
 * contribute nothing to the track's intrinsic width - the track sized to less
 * than its labels and every segment got 1/n of too little, clipping the longest.
 * `grid-auto-columns: 1fr` is `minmax(auto, 1fr)`: columns come out equal *and*
 * no narrower than the widest label, which is what a switch needs.
 */
.btn-group--segmented .btn-group__track {
  @apply bg-transparent relative grid;
  grid-auto-flow: column;
  grid-auto-columns: 1fr;
  gap: 0;
}

.btn-group__thumb {
  @apply bg-control border-edge absolute border;
  top: 0;
  bottom: 0;
  left: 0;
  width: calc(100% / var(--seg-count, 2));
  border-radius: var(--radius-control-inner, 7px);
  transform: translateX(calc(var(--seg-index, 0) * 100%));
  transition: transform 150ms ease;
}

/* The grid sizes the segments; the member only drops its fill, since the thumb is
   the fill. No min-width: 0 - that is what let a label be crushed. */
.btn-group--segmented :deep(.btn--grouped) {
  background: transparent;
}

@media (prefers-reduced-motion: reduce) {
  .btn-group__thumb {
    transition: none;
  }
}

.btn-group--block {
  @apply flex w-full;
}

/*
 * A group can contain a plain label segment as well as buttons - the paginator
 * puts its "1 of 9" in a bare span. Give it the same surface as a member,
 * otherwise the track's fill shows straight through and the label reads as a
 * highlighted panel. Direct children only, so .btn__content inside a member is
 * untouched.
 */
.btn-group__track > :deep(span) {
  @apply bg-control text-text flex items-center justify-center px-3.5;
  /* Mirrors .btn--sm's label, since a group with a label segment is a paginator
     and paginators are sm. If Btn's type scale moves, this moves with it - it
     cannot inherit, because size is a per-member prop the group cannot see. */
  @apply text-[15px] leading-tight font-normal whitespace-nowrap;
}
</style>
