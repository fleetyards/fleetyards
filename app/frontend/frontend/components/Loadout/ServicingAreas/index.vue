<script lang="ts">
export default {
  name: "LoadoutServicingAreas",
};
</script>

<script lang="ts" setup>
import type { ModelLoadoutPreviewServicingArea } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  title?: string;
  areas: ModelLoadoutPreviewServicingArea[];
  testId?: string;
};

withDefaults(defineProps<Props>(), {
  title: undefined,
  testId: "loadout-servicing-areas",
});

const emit = defineEmits<{
  point: [key: string | undefined];
}>();

const { t, toNumber } = useI18n();

// The export's size runs across, up and along the box; the ship's page reads
// length, width and height.
const dimensions = (area: ModelLoadoutPreviewServicingArea) => {
  const [width, height, length] = area.size;

  return `${toNumber(length)} × ${toNumber(width)} × ${toNumber(height)} m`;
};
</script>

<template>
  <section class="loadout-servicing-areas" :data-test="testId">
    <h4 v-if="title" class="loadout-servicing-areas__title">{{ title }}</h4>
    <dl class="loadout-servicing-areas__list">
      <div
        v-for="area in areas"
        :key="area.key"
        class="loadout-servicing-areas__area"
        :data-test="`${testId}-${area.index}`"
        @mouseenter="emit('point', area.key)"
        @mouseleave="emit('point', undefined)"
      >
        <dt>
          {{ area.name || t("model.servicingArea", { index: area.index }) }}
        </dt>
        <dd>{{ dimensions(area) }}</dd>
      </div>
    </dl>
  </section>
</template>

<style lang="scss" scoped>
.loadout-servicing-areas {
  align-self: stretch;
  text-align: left;
}

.loadout-servicing-areas__title {
  margin: 0 0 6px;
  color: var(--color-text-dim);
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 0.625rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.loadout-servicing-areas__list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
  gap: 4px 16px;
  margin: 0;
}

.loadout-servicing-areas__area {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
  padding: 3px 0;
  border-bottom: 1px solid var(--color-edge-faint);
  font-size: 0.75rem;
  cursor: default;

  dt {
    overflow: hidden;
    color: var(--color-text-dim);
    font-weight: 400;
    white-space: nowrap;
    text-overflow: ellipsis;
  }

  dd {
    flex: none;
    margin: 0;
    color: var(--color-lifted);
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }

  &:hover dt {
    color: var(--color-lifted);
  }
}
</style>
