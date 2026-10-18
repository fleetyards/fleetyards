<script lang="ts">
export default {
  name: "HangarSyncReadCounts",
};
</script>

<script lang="ts" setup>
import NumberFlow from "@number-flow/vue";
import type { SyncReadCount } from "./types";

type Props = {
  counts: SyncReadCount[];
};

const props = defineProps<Props>();

// A kind with nothing in it yet stays out of the way; pages always show.
const shown = computed(() =>
  props.counts.filter((entry) => entry.key === "pages" || entry.count > 0),
);
</script>

<template>
  <!--
    Each number counts up in place, and a kind that turns up fades in while the
    cells already there slide aside: nothing jumps while pages come in.
  -->
  <TransitionGroup tag="dl" name="sync-read-counts" class="sync-read-counts">
    <div
      v-for="entry in shown"
      :key="entry.key"
      class="sync-read-counts__cell"
      :class="{
        'sync-read-counts__cell--empty': !entry.count,
        'sync-read-counts__cell--skipped': entry.skipped,
      }"
      :data-test="`sync-read-${entry.key}`"
    >
      <dt :data-test="entry.dataTest">{{ entry.label }}</dt>
      <dd :data-count="entry.count">
        <NumberFlow :value="entry.count" />
      </dd>
    </div>
  </TransitionGroup>
</template>

<style lang="scss" scoped>
.sync-read-counts {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(118px, 1fr));
  gap: 6px 8px;
  margin: 0;
}

.sync-read-counts__cell {
  display: flex;
  flex-direction: column-reverse;
  justify-content: flex-end;
  gap: 1px;
  padding: 6px 10px;
  border: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  border-radius: var(--radius-control, 8px);

  dt {
    color: var(--color-text-dim, #959595);
    font-size: 12px;
    font-weight: normal;
    line-height: 1.3;
  }

  dd {
    margin: 0;
    color: var(--color-lifted, #eee);
    font-size: 17px;
    line-height: 1.25;
    font-variant-numeric: tabular-nums;
  }
}

.sync-read-counts__cell--empty dd {
  color: var(--color-muted, #7a8288);
}

.sync-read-counts-enter-active,
.sync-read-counts-move {
  transition:
    opacity 250ms ease,
    transform 250ms ease;
}

.sync-read-counts-enter-from {
  opacity: 0;
  transform: scale(0.9);
}

@media (prefers-reduced-motion: reduce) {
  .sync-read-counts-enter-active,
  .sync-read-counts-move {
    transition: none;
  }
}

.sync-read-counts__cell--skipped dt {
  font-style: italic;
}
</style>
