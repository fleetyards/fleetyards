<script lang="ts">
export default {
  name: "EquipmentGearStats",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useGearStatSections } from "@/frontend/composables/useGearStatSections";
import { useI18n } from "@/shared/composables/useI18n";
import { type EquipmentStats } from "@/services/fyApi";

type Props = {
  stats?: EquipmentStats | null;
};

const props = withDefaults(defineProps<Props>(), {
  stats: undefined,
});

const { t } = useI18n();

const sections = useGearStatSections(() => props.stats);
</script>

<template>
  <section v-if="sections.length" class="gear-stats" data-test="gear-stats">
    <Heading level="h2" size="lg" mt mb>
      {{ t("headlines.equipment.performance") }}
    </Heading>

    <div class="gear-stats__cards">
      <MetricsCard
        v-for="section in sections"
        :key="section.key"
        :title="section.title"
        variant="slim"
        :data-test="`gear-stats-${section.key}`"
      >
        <div class="metrics-card__rows">
          <div
            v-for="row in section.rows"
            :key="row.label"
            class="metrics-card__row"
            :class="{ 'metrics-card__row--stack': row.stack }"
          >
            <span class="metrics-card__row__label">{{ row.label }}</span>
            <span class="metrics-card__row__value">{{ row.value }}</span>
          </div>
        </div>
      </MetricsCard>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.gear-stats__cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 22px;
  align-items: start;
}
</style>
