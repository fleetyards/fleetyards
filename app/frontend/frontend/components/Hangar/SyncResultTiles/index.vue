<script lang="ts">
export default {
  name: "HangarSyncResultTiles",
};
</script>

<script lang="ts" setup>
export type SyncResultTile = {
  key: string;
  value: number | string;
  label: string;
  // For a caller whose tests read the number on its own.
  valueTest?: string;
};

type Props = {
  tiles: SyncResultTile[];
};

defineProps<Props>();
</script>

<template>
  <dl class="sync-result-tiles">
    <div
      v-for="tile in tiles"
      :key="tile.key"
      class="sync-result-tiles__tile"
      :data-test="`sync-result-tile-${tile.key}`"
    >
      <dt class="sync-result-tiles__label">{{ tile.label }}</dt>
      <dd class="sync-result-tiles__value" :data-test="tile.valueTest">
        {{ tile.value }}
      </dd>
    </div>
  </dl>
</template>

<style lang="scss" scoped>
.sync-result-tiles {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(108px, 1fr));
  gap: 10px;
  margin: 0;
}

// The number reads first, the label under it; in the markup the label stays
// the term the number describes.
.sync-result-tiles__tile {
  display: flex;
  flex-direction: column-reverse;
  justify-content: flex-end;
  gap: 2px;
  padding: 10px 12px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.sync-result-tiles__value {
  margin: 0;
  color: var(--color-lifted, #eee);
  font-size: 22px;
  line-height: 1.2;
  font-variant-numeric: tabular-nums;
}

.sync-result-tiles__label {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
  font-weight: normal;
  line-height: 1.3;
}
</style>
