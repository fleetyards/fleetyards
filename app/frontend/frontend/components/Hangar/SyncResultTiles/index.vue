<script lang="ts">
export default {
  name: "HangarSyncResultTiles",
};
</script>

<script lang="ts" setup>
import NumberFlow from "@number-flow/vue";
import type { SyncResultTile } from "./types";

type Props = {
  tiles: SyncResultTile[];
};

defineProps<Props>();
</script>

<template>
  <!--
    One look for a run in progress and its result. A number counts up in place,
    and a tile that turns up fades in while the others slide aside, so nothing
    jumps while a run is reading.
  -->
  <TransitionGroup tag="dl" name="sync-result-tiles" class="sync-result-tiles">
    <div
      v-for="tile in tiles"
      :key="tile.key"
      class="sync-result-tiles__tile"
      :class="{ 'sync-result-tiles__tile--skipped': tile.skipped }"
      :data-test="`sync-result-tile-${tile.key}`"
    >
      <dt class="sync-result-tiles__label" :data-test="tile.labelTest">
        {{ tile.label }}
        <span v-if="tile.note" class="sync-result-tiles__note">
          {{ tile.note }}
        </span>
      </dt>
      <dd
        class="sync-result-tiles__value"
        :data-test="tile.valueTest"
        :data-count="typeof tile.value === 'number' ? tile.value : undefined"
      >
        <NumberFlow v-if="typeof tile.value === 'number'" :value="tile.value" />
        <template v-else>{{ tile.value }}</template>
      </dd>
    </div>
  </TransitionGroup>
</template>

<style lang="scss" scoped>
.sync-result-tiles {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(112px, 1fr));
  gap: 8px;
  margin: 0;
}

// The number reads first, the label under it; in the markup the label stays
// the term the number describes.
.sync-result-tiles__tile {
  display: flex;
  flex-direction: column-reverse;
  justify-content: flex-end;
  gap: 2px;
  padding: 8px 12px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.sync-result-tiles__value {
  margin: 0;
  color: var(--color-lifted, #eee);
  font-size: 20px;
  line-height: 1.2;
  font-variant-numeric: tabular-nums;
}

.sync-result-tiles__label {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
  font-weight: normal;
  line-height: 1.3;
}

.sync-result-tiles__tile--skipped .sync-result-tiles__label {
  font-style: italic;
}

.sync-result-tiles__note {
  display: block;
  color: var(--color-success, #5cb85c);
  font-size: 12px;
}

.sync-result-tiles-enter-active,
.sync-result-tiles-move {
  transition:
    opacity 250ms ease,
    transform 250ms ease;
}

.sync-result-tiles-enter-from {
  opacity: 0;
  transform: scale(0.9);
}

@media (prefers-reduced-motion: reduce) {
  .sync-result-tiles-enter-active,
  .sync-result-tiles-move {
    transition: none;
  }
}
</style>
