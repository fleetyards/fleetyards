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
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
});

const { t, toNumber } = useI18n();

const stats = useShieldStats(() => props.hardpoints);

const round = (value: number) => Math.round(value);
</script>

<template>
  <div v-if="stats.hasData" class="metrics-card survivability-panel">
    <div class="metrics-card__head">
      <span class="metrics-card__title">
        <span class="metrics-card__dot" />
        {{ t("labels.survivability.title") }}
      </span>
    </div>

    <div class="metrics-card__body">
      <div class="metrics-card__hero">
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">
            {{ t("labels.survivability.shieldHp") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(stats.totalHp), "integer") }}
            <span class="metrics-card__tile__unit">HP</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.survivability.shieldHpSub") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.survivability.regen") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(stats.totalRegen), "integer") }}
            <span class="metrics-card__tile__unit">HP/s</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.survivability.regenSub") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.survivability.shields") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(stats.shieldCount, "integer") }}
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
