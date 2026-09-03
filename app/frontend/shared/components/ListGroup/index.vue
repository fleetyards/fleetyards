<script lang="ts">
export default {
  name: "ListGroup",
};
</script>

<script lang="ts" setup generic="T extends { id: string }">
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import {
  useListGeometry,
  useReportListGeometry,
} from "@/shared/composables/useListGeometry";
import { useMinimumDuration } from "@/shared/composables/useMinimumDuration";

type Props = {
  items: T[];
  loading?: boolean;
  emptyName?: string;
  hideEmpty?: boolean;
  // The row whose content slot holds a tall panel rather than a single line.
  // Its actions align to the bottom instead of floating in the middle of it.
  expandedId?: string | null;
  // Placeholder rows to hold the list open with while it waits for its first
  // records. A list framed by a FilteredList takes the count from the frame
  // instead, so this is only for one standing on its own.
  skeletonRows?: number;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  emptyName: "entries",
  hideEmpty: false,
  expandedId: undefined,
  skeletonRows: undefined,
});

// A frame - FilteredList - offers this list its page size and what one of its
// rows measured last time. A list standing on its own has neither.
const geometry = useListGeometry();

// A list on its own is handed a query's own flag, and a cached page answers
// inside a frame or two: placeholders that go up and come down that fast read
// as the page glitching rather than as the page loading. A framed list needs no
// hold of its own, because the frame has already held the flag before deciding
// to render this list, and holding it twice only stacks a second wait on the
// first. See useMinimumDuration.
const loading = geometry
  ? computed(() => props.loading)
  : useMinimumDuration(() => props.loading);

// `??`, not `||`: a remembered zero means this list has been seen empty, and
// reserving nothing for it is the right answer rather than a missing one.
//
// Three where nothing is known at all. These lists are short - a ship's docks,
// an item's prices - and carry no page size to read a bound off, so a full page
// of placeholders would claim a screenful of nothing to stand in for four rows.
const skeletonRowCount = computed(
  () => props.skeletonRows ?? geometry?.count.value ?? 3,
);

// Only for the first load. A refetch keeps the records it already has on
// screen, and they hold the list open better than placeholders would.
const skeletonVisible = computed(
  () => !!skeletonRowCount.value && loading.value && !props.items.length,
);

// Held back only where the frame around this list is already showing one over
// the placeholder rows. A list loading on its own keeps it.
const loaderVisible = computed(() => {
  if (!loading.value) {
    return false;
  }

  return !(skeletonVisible.value && !!geometry?.spinnerVisible.value);
});

// What a row of this list measured, which only a frame is in a position to
// remember - a list on its own has nowhere to keep it. Worth having where it is
// there: a display slot that wraps to two lines is taller than anything the
// stylesheet can build ahead of time.
//
// Unmeasured, the placeholder is built to the recipe these rows are made of and
// comes out right without it: 47px against 47px for a row holding a pill and a
// name, 61px against 61px once it carries buttons.
const skeletonRowHeight = computed(() => {
  const remembered = geometry?.heightFor("row");

  return remembered ? `${remembered}px` : undefined;
});

const inner = ref<HTMLElement>();

// The row rather than the item: an item wraps the expanded slot too, and a
// placeholder stands in for the row alone. An open row is skipped for the same
// reason - it is as tall as the edit panel inside it, which is no reading of
// how tall a row of this list is.
useReportListGeometry("row", inner, {
  ready: () => !!props.items.length,
  pick: (host) =>
    Array.from(
      host.querySelectorAll<HTMLElement>(
        "[data-test='list-group-item'] > .list-group__row",
      ),
    ).find(
      (candidate) => !candidate.classList.contains("list-group__row--expanded"),
    ),
});
</script>

<template>
  <div ref="inner" class="list-group">
    <TransitionGroup name="list">
      <slot name="prepend" />

      <div
        v-for="item in items"
        :key="item.id"
        class="list-group__item"
        data-test="list-group-item"
      >
        <div
          class="list-group__row"
          :class="{ 'list-group__row--expanded': item.id === expandedId }"
        >
          <div class="list-group__content">
            <slot name="display" :item="item" />
          </div>
          <div class="list-group__actions">
            <slot name="actions" :item="item" />
          </div>
        </div>
        <slot name="expanded" :item="item" />
      </div>
    </TransitionGroup>

    <!-- Built to the row's own recipe rather than to a height written by hand:
         the same frame, the same insets and the same type, so the height falls
         out of the same arithmetic the row's does.
         Outside the transition group on purpose. A leaving row of that group
         keeps its place in the column for the half second it fades, so
         placeholders inside it would stand under the records that just landed
         and hold the list at twice its height until they went - the jump the
         placeholders are here to prevent. Records enter in place, so dropping
         the placeholders in the same frame costs the list no height. -->
    <template v-if="skeletonVisible">
      <div
        v-for="row in skeletonRowCount"
        :key="`list-group__skeleton-${row}`"
        class="list-group__item list-group__item--skeleton"
        aria-hidden="true"
        data-test="list-group-skeleton-row"
      >
        <div class="list-group__row" :style="{ height: skeletonRowHeight }">
          <div class="list-group__content">
            <span class="skeleton-bar skeleton-bar--pill" />
            <span class="skeleton-bar skeleton-bar--label" />
          </div>
          <!-- Only where the rows of this list carry buttons, since it is the
               block that makes the placeholder as tall as one of them. -->
          <div v-if="$slots.actions" class="list-group__actions">
            <span class="skeleton-bar skeleton-bar--control" />
          </div>
        </div>
      </div>
    </template>

    <Loader :loading="loaderVisible" />

    <Empty
      v-if="!items.length && !loading && !hideEmpty"
      variant="box"
      hide-actions
      :name="emptyName"
    />
  </div>
</template>

<style lang="scss">
@import "index";
</style>
