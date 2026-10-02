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
};

const props = defineProps<Props>();

const { t } = useI18n();

const groups = useComponentDurability(() => props.durability);
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
            <span class="metrics-card__row__value">{{ stat.value }}</span>
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
</style>
