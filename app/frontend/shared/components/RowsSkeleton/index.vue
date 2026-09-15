<script lang="ts">
export default {
  name: "RowsSkeleton",
};
</script>

<script lang="ts" setup>
type Props = {
  // How many rows to hold the panel open with. Kept small by default: these
  // stand inside a panel that is already sized by the page around it, and a
  // list of ten placeholders where three records land is a panel that shrinks.
  count?: number;
  // A leading icon or avatar column, for the lists whose rows carry one.
  icon?: boolean;
  // A figure right-aligned at the end of the row - an amount, a count.
  trailing?: boolean;
  // A second, quieter line under the first, for rows that carry a subtitle.
  meta?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  count: 3,
  icon: false,
  trailing: false,
  meta: true,
});

// Staggered so the column does not read as a form with identical fields. See
// DetailSkeleton, which does the same for its paragraphs.
const TITLE_WIDTHS = ["70%", "52%", "63%", "45%"];

const titleWidth = (row: number) =>
  TITLE_WIDTHS[(row - 1) % TITLE_WIDTHS.length];
</script>

<template>
  <div class="rows-skeleton" aria-hidden="true" data-test="rows-skeleton">
    <div
      v-for="row in props.count"
      :key="`rows-skeleton-${row}`"
      class="rows-skeleton__row"
    >
      <span v-if="props.icon" class="rows-skeleton__icon" />

      <span class="rows-skeleton__lines">
        <span class="skeleton-bar" :style="{ width: titleWidth(row) }" />
        <span v-if="props.meta" class="skeleton-bar skeleton-bar--meta" />
      </span>

      <span v-if="props.trailing" class="skeleton-bar skeleton-bar--trailing" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
