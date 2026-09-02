<script lang="ts">
export default {
  name: "GridSkeleton",
};
</script>

<script lang="ts" setup>
import Grid from "@/shared/components/base/Grid/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { useListGeometry } from "@/shared/composables/useListGeometry";

type Props = {
  // Both come from the list this stands in for when it is inside one.
  count?: number;
  details?: boolean;
  filterVisible?: boolean;
  gridBase?: "2" | "3";
  // What the cells of this grid hold. `panel` is a card - a photo with a title
  // over it and a frame around it. The other two are bare: `image` a gallery
  // picture, which is as tall as its token whatever the column width, and
  // `embed` a video, which is 16:9 of it.
  variant?: "panel" | "image" | "embed";
};

const props = withDefaults(defineProps<Props>(), {
  count: undefined,
  details: false,
  filterVisible: false,
  gridBase: "3",
  variant: "panel",
});

const geometry = useListGeometry();

// `??`, not `||`: a remembered zero means this list has been seen empty, and
// reserving nothing for it is the right answer rather than a missing one.
const count = computed(() => props.count ?? geometry?.count.value ?? 10);

// Nothing until this grid has been seen once, and then exactly what a card of
// it measured: the image floor below only has to carry the very first load.
const cardHeight = computed(() => {
  const remembered = geometry?.heightFor("card");

  return remembered ? `${remembered}px` : undefined;
});

// Grid keys its cells off a field of the record, so the placeholders need one -
// the index, which is stable for as long as the count is.
const cells = computed(() =>
  Array.from({ length: count.value }, (_, index) => ({
    key: `grid-skeleton-${index}`,
  })),
);

// What an expanded ship card carries: focus, crew and speed above the divider,
// then the five dimensions and the price in two columns. See
// useModelMetricRows.
const summaryRows = 3;
const dimensionRows = 6;
</script>

<template>
  <Grid
    :records="cells"
    primary-key="key"
    :grid-base="props.gridBase"
    :filter-visible="props.filterVisible"
    class="grid-skeleton"
    aria-hidden="true"
    data-test="grid-skeleton"
  >
    <!-- No frame and no title: a cell of the image grid holds the picture
         itself, and one of the video grid the embed. -->
    <span
      v-if="props.variant !== 'panel'"
      class="grid-skeleton__bare skeleton-well"
      :class="`grid-skeleton__bare--${props.variant}`"
      :style="{ height: cardHeight }"
    />

    <!-- A height, not a minimum: a measured card can be shorter than the image
         floor below - an image card is - and a floor it cannot go under would
         hold the placeholder taller than the card it stands in for. -->
    <Panel
      v-else
      class="grid-skeleton__panel"
      :class="{ 'grid-skeleton__panel--measured': !!cardHeight }"
      :style="{ height: cardHeight }"
    >
      <template #default>
        <div
          class="grid-skeleton__media skeleton-well"
          :class="{ 'grid-skeleton__media--open': props.details }"
        >
          <div class="grid-skeleton__heading">
            <span class="skeleton-bar skeleton-bar--title" />
            <span class="skeleton-bar skeleton-bar--subtitle" />
          </div>
        </div>
      </template>

      <template v-if="props.details" #footer>
        <div class="grid-skeleton__status">
          <span class="skeleton-bar skeleton-bar--status" />
        </div>
        <div class="grid-skeleton__metrics">
          <div class="metrics-card__rows">
            <div
              v-for="row in summaryRows"
              :key="`grid-skeleton__summary-${row}`"
              class="metrics-card__row"
            >
              <span class="metrics-card__row__label">
                <span class="skeleton-bar" />
              </span>
              <span class="metrics-card__row__value">
                <span class="skeleton-bar" />
              </span>
            </div>
          </div>
          <div class="metrics-card__divider" />
          <div class="metrics-card__rows metrics-card__rows--split">
            <div
              v-for="row in dimensionRows"
              :key="`grid-skeleton__dimension-${row}`"
              class="metrics-card__row"
            >
              <span class="metrics-card__row__label">
                <span class="skeleton-bar" />
              </span>
              <span class="metrics-card__row__value">
                <span class="skeleton-bar" />
              </span>
            </div>
          </div>
        </div>
      </template>
    </Panel>
  </Grid>
</template>

<style lang="scss" scoped>
@import "index";
</style>
