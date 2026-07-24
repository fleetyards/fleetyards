<script lang="ts">
export default {
  name: "ModelCombatMetrics",
};
</script>

<script lang="ts" setup>
import type { Hardpoint } from "@/services/fyApi";
import Collapsed from "@/shared/components/Collapsed.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useLoadoutStats,
  type DamageBreakdown,
} from "@/frontend/composables/useLoadoutStats";

type Props = {
  hardpoints?: Hardpoint[];
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
});

const { t, toNumber } = useI18n();

const stats = useLoadoutStats(() => props.hardpoints);

const round = (value: number) => Math.round(value);

const expanded = ref(false);
const hoveredType = ref<string | null>(null);

const damageTypes: { key: keyof DamageBreakdown; label: string }[] = [
  { key: "physical", label: "labels.combat.damagePhysical" },
  { key: "energy", label: "labels.combat.damageEnergy" },
  { key: "distortion", label: "labels.combat.damageDistortion" },
  { key: "thermal", label: "labels.combat.damageThermal" },
];

const composition = computed(() => {
  const total = stats.value.dps.total;
  if (!total) return [];

  return damageTypes
    .map(({ key, label }) => ({
      key,
      label,
      value: stats.value.dps[key],
      pct: (stats.value.dps[key] / total) * 100,
    }))
    .filter((entry) => entry.value > 0)
    .sort((a, b) => b.value - a.value);
});
</script>

<template>
  <div v-if="stats.hasData" class="metrics-card combat-panel">
    <div class="metrics-card__head">
      <span class="metrics-card__title">
        <span class="metrics-card__dot" />
        {{ t("labels.combat.title") }}
      </span>
    </div>

    <div class="metrics-card__body">
      <div class="metrics-card__hero">
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">{{ t("labels.combat.dps") }}</div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(stats.dps.total), "integer") }}
            <span class="metrics-card__tile__unit">DPS</span>
          </div>
          <div class="metrics-card__tile__sub">{{ t("labels.combat.dpsSub") }}</div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">{{ t("labels.combat.alpha") }}</div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(stats.alpha.total), "integer") }}
            <span class="metrics-card__tile__unit">DMG</span>
          </div>
          <div class="metrics-card__tile__sub">{{ t("labels.combat.alphaSub") }}</div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">{{ t("labels.combat.weapons") }}</div>
          <div class="metrics-card__tile__value">
            {{ toNumber(stats.weaponCount, "integer") }}
          </div>
        </div>
      </div>

      <div class="metrics-card__section-label">
        {{ t("labels.combat.composition") }}
      </div>
      <div
        class="compbar"
        :class="{ 'compbar--dimmed': hoveredType }"
      >
        <div
          v-for="seg in composition"
          :key="seg.key"
          class="compbar__seg"
          :class="{ 'compbar__seg--active': hoveredType === seg.key }"
          :data-type="seg.key"
          :style="{ width: `${seg.pct}%` }"
        />
      </div>

      <div class="legend">
        <div
          v-for="seg in composition"
          :key="seg.key"
          class="legend__row"
          @mouseenter="hoveredType = seg.key"
          @mouseleave="hoveredType = null"
        >
          <span class="legend__swatch" :data-type="seg.key" />
          <span class="legend__label">{{ t(seg.label) }}</span>
          <span class="legend__value">{{ toNumber(round(seg.value), "integer") }}</span>
          <span class="legend__pct">{{ toNumber(round(seg.pct), "integer") }}%</span>
        </div>
      </div>

      <Collapsed :visible="expanded" :duration="200">
        <div class="metrics-card__divider" />
        <table class="weapon-table">
          <thead>
            <tr>
              <th>{{ t("labels.combat.weaponName") }}</th>
              <th class="num">{{ t("labels.combat.size") }}</th>
              <th class="num">{{ t("labels.combat.dps") }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="weapon in stats.weapons" :key="weapon.id">
              <td class="weapon-table__name">{{ weapon.name }}</td>
              <td class="num">
                <span v-if="weapon.size">S{{ weapon.size }}</span>
                <span v-else>—</span>
              </td>
              <td class="num">{{ toNumber(round(weapon.dps), "integer") }}</td>
            </tr>
          </tbody>
        </table>
      </Collapsed>

      <div class="metrics-card__footer">
        <button
          type="button"
          class="metrics-card__toggle"
          @click="expanded = !expanded"
        >
          {{
            expanded
              ? t("labels.combat.hideBreakdown")
              : t("labels.combat.showBreakdown")
          }}
        </button>
        <span class="metrics-card__hint">{{ t("labels.combat.hint") }}</span>
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

.compbar {
  display: flex;
  height: 16px;
  border-radius: 999px;
  overflow: hidden;
  background: $gray-black;
  border: 1px solid rgba($gray-light, 0.28);

  &__seg {
    height: 100%;
    transition: opacity 0.18s ease;

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

  &--dimmed &__seg:not(&__seg--active) {
    opacity: 0.25;
  }
}

.legend {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4px 22px;
  margin-top: 16px;

  @media (max-width: 576px) {
    grid-template-columns: 1fr;
  }

  &__row {
    display: grid;
    grid-template-columns: auto 1fr auto auto;
    align-items: center;
    gap: 9px;
    padding: 5px 6px;
    border-radius: 6px;
    transition: background 0.15s ease;

    &:hover {
      background: rgba(#fff, 0.03);
    }
  }

  &__swatch {
    width: 9px;
    height: 9px;
    border-radius: 2px;

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

  &__label {
    font-size: 13px;
    color: $text-color;
  }

  &__value {
    font-weight: 700;
    font-size: 13px;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &__pct {
    font-size: 12px;
    color: $gray-light;
    min-width: 42px;
    text-align: right;
    font-variant-numeric: tabular-nums;
  }
}

.weapon-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;

  th {
    text-align: left;
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 400;
    font-size: 9.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray;
    padding: 0 10px 8px 0;
    border-bottom: 1px solid rgba($gray-light, 0.28);
  }

  td {
    padding: 9px 10px 9px 0;
    border-bottom: 1px solid rgba($gray-light, 0.28);
    color: $text-color;
  }

  tr:last-child td {
    border-bottom: 0;
  }

  .num {
    text-align: right;
    padding-right: 0;
    font-variant-numeric: tabular-nums;
  }

  &__name {
    color: lighten($text-color, 15%);
  }
}
</style>
