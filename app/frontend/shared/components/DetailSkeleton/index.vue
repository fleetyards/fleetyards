<script lang="ts">
export default {
  name: "DetailSkeleton",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";

type Props = {
  // The cover a detail page opens on, with its title and byline standing over
  // the bottom of it the way the real hero's do.
  hero?: boolean;
  // The strip of figures that overlaps the hero's seam. Zero leaves it out
  // entirely - a page whose hero is followed straight by its body.
  figures?: number;
  // Panels below the figures, and how many lines each of them holds. One line
  // is a heading on its own; the default is a heading and a short body.
  panels?: number;
  panelRows?: number;
};

const props = withDefaults(defineProps<Props>(), {
  hero: true,
  figures: 0,
  panels: 2,
  panelRows: 3,
});

// A width per line rather than one for all of them: a column of bars all ending
// at the same point reads as a table, which is not what a paragraph looks like.
// The cycle is short enough that a panel of any length keeps a ragged edge.
const ROW_WIDTHS = ["92%", "78%", "85%", "64%"];

const rowWidth = (row: number) => ROW_WIDTHS[(row - 1) % ROW_WIDTHS.length];
</script>

<template>
  <div class="detail-skeleton" aria-hidden="true" data-test="detail-skeleton">
    <div v-if="props.hero" class="detail-skeleton__hero skeleton-well">
      <div class="detail-skeleton__hero-body">
        <span class="skeleton-bar skeleton-bar--kind" />
        <span class="skeleton-bar skeleton-bar--title" />
        <span class="skeleton-bar skeleton-bar--byline" />
      </div>
    </div>

    <div
      v-if="props.figures"
      class="metrics-card__hero detail-skeleton__figures"
    >
      <div
        v-for="figure in props.figures"
        :key="`detail-skeleton__figure-${figure}`"
        class="metrics-card__tile"
        :class="{ 'metrics-card__tile--primary': figure === 1 }"
      >
        <div class="metrics-card__tile__label">
          <span class="skeleton-bar skeleton-bar--label" />
        </div>
        <div class="metrics-card__tile__value">
          <span class="skeleton-bar skeleton-bar--figure" />
        </div>
      </div>
    </div>

    <Panel
      v-for="panel in props.panels"
      :key="`detail-skeleton__panel-${panel}`"
    >
      <div class="detail-skeleton__panel-body">
        <span
          v-for="row in props.panelRows"
          :key="`detail-skeleton__panel-${panel}-row-${row}`"
          class="skeleton-bar"
          :class="{ 'skeleton-bar--heading': row === 1 }"
          :style="{ width: row === 1 ? undefined : rowWidth(row) }"
        />
      </div>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
