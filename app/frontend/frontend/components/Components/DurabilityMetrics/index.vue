<script lang="ts">
export default {
  name: "ComponentDurabilityMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { ComponentDurability } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentDurability } from "@/frontend/composables/useComponentDurability";

type Props = {
  durability?: ComponentDurability | null;
  // The catalogue's figures, where `durability` is a crafted part's: what
  // crafting moved is marked against them.
  stock?: ComponentDurability | null;
};

const props = withDefaults(defineProps<Props>(), {
  durability: undefined,
  stock: undefined,
});

const { t } = useI18n();

const groups = useComponentDurability(() => props.durability);
const stockGroups = useComponentDurability(() => props.stock);

// What the catalogue says for a figure, where it says something else.
const stockValue = (groupKey: string, label: string, value: string) => {
  if (!props.stock) return undefined;

  const original = stockGroups.value
    .find((group) => group.key === groupKey)
    ?.stats.find((stat) => stat.label === label)?.value;

  return original !== undefined && original !== value ? original : undefined;
};
</script>

<template>
  <MetricsCard
    v-if="groups.length"
    :title="t('headlines.component.durability')"
    data-test="component-durability"
  >
    <div class="durability-metrics">
      <section
        v-for="group in groups"
        :key="group.key"
        :data-test="`durability-${group.key}`"
      >
        <div class="metrics-card__section-label">
          {{ t(`headlines.component.${group.key}`) }}
        </div>
        <div class="metrics-card__rows">
          <div
            v-for="stat in group.stats"
            :key="stat.label"
            class="metrics-card__row"
          >
            <span class="metrics-card__row__label">{{ stat.label }}</span>
            <span
              v-tooltip="
                stockValue(group.key, stat.label, stat.value)
                  ? t('labels.statsCard.stock', {
                      value: stockValue(group.key, stat.label, stat.value),
                    })
                  : undefined
              "
              class="metrics-card__row__value"
              :class="{
                'durability-metrics__changed': stockValue(
                  group.key,
                  stat.label,
                  stat.value,
                ),
              }"
            >
              {{ stat.value }}
            </span>
          </div>
        </div>
      </section>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.durability-metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 18px 26px;
}

// Moved off the catalogue's figure by crafting, in the colour the stats card
// marks the same thing with.
.metrics-card__row__value.durability-metrics__changed {
  color: var(--color-primary, #428bca);
}
</style>
