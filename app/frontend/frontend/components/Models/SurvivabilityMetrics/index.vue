<script lang="ts">
export default {
  name: "ModelSurvivabilityMetrics",
};
</script>

<script lang="ts" setup>
import type { Hardpoint } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useShieldStats } from "@/frontend/composables/useShieldStats";

type Props = {
  hardpoints?: Hardpoint[];
  hullHealth?: number;
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
  hullHealth: undefined,
});

const { t, toNumber } = useI18n();

const stats = useShieldStats(() => props.hardpoints);

const round = (value: number) => Math.round(value);

const hasHull = computed(() => (props.hullHealth ?? 0) > 0);
const hasData = computed(() => stats.value.hasData || hasHull.value);
</script>

<template>
  <div v-if="hasData" class="metrics-card survivability-panel">
    <div class="metrics-card__head">
      <span class="metrics-card__title">
        <span class="metrics-card__dot" />
        {{ t("labels.survivability.title") }}
      </span>
    </div>

    <div class="metrics-card__body">
      <div class="metrics-card__hero">
        <div
          v-if="stats.hasData"
          class="metrics-card__tile metrics-card__tile--primary"
        >
          <div class="metrics-card__tile__label">
            {{ t("labels.survivability.shieldHp") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(stats.totalHp), "integer") }}
            <span class="metrics-card__tile__unit">HP</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ toNumber(stats.totalRegen, "integer") }} HP/s ·
            {{ toNumber(stats.shieldCount, "integer") }}×
          </div>
        </div>
        <div
          v-if="hasHull"
          class="metrics-card__tile"
          :class="{ 'metrics-card__tile--primary': !stats.hasData }"
        >
          <div class="metrics-card__tile__label">
            {{ t("labels.survivability.hullHp") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(hullHealth ?? 0), "integer") }}
            <span class="metrics-card__tile__unit">HP</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.survivability.hullHpSub") }}
          </div>
        </div>
      </div>

      <template v-if="stats.resistances.length">
        <div class="metrics-card__section-label">
          {{ t("labels.survivability.resistances") }}
        </div>
        <div class="resist">
          <div
            v-for="resistance in stats.resistances"
            :key="resistance.key"
            class="resist__row"
          >
            <span class="resist__label">{{ t(resistance.label) }}</span>
            <div class="resist__track">
              <div
                class="resist__fill"
                :data-type="resistance.key"
                :style="{ width: `${resistance.value * 100}%` }"
              />
            </div>
            <span class="resist__value">
              {{ toNumber(round(resistance.value * 100), "integer") }}%
            </span>
          </div>
        </div>
      </template>

      <div class="metrics-card__footer">
        <span class="metrics-card__hint">
          {{ t("labels.survivability.hint") }}
        </span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

.metrics-card__hero {
  grid-template-columns: 1.5fr 1fr;

  @media (max-width: 576px) {
    grid-template-columns: 1fr;
  }
}

$c-physical: $text-color;
$c-energy: $primary;
$c-distortion: $cyan;
$c-thermal: $warning;

.resist {
  display: grid;
  gap: 10px;

  &__row {
    display: grid;
    grid-template-columns: 90px 1fr 48px;
    align-items: center;
    gap: 12px;
  }

  &__label {
    font-size: 13px;
    color: $text-color;
  }

  &__track {
    height: 8px;
    border-radius: 999px;
    background: $gray-black;
    border: 1px solid rgba($gray-light, 0.28);
    overflow: hidden;
  }

  &__fill {
    height: 100%;
    border-radius: 999px;

    &[data-type="physical"] {
      background: $c-physical;
    }
    &[data-type="energy"] {
      background: $c-energy;
    }
    &[data-type="distortion"] {
      background: $c-distortion;
    }
    &[data-type="thermal"] {
      background: $c-thermal;
    }
  }

  &__value {
    font-size: 12px;
    color: $gray-light;
    text-align: right;
    font-variant-numeric: tabular-nums;
  }
}
</style>
