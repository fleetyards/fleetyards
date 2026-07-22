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
  <div v-if="stats.hasData" class="combat-panel">
    <div class="combat-panel__head">
      <span class="combat-panel__title">
        <span class="combat-panel__dot" />
        {{ t("labels.combat.title") }}
      </span>
    </div>

    <div class="combat-panel__body">
      <div class="combat-panel__hero">
        <div class="tile tile--primary">
          <div class="tile__label">{{ t("labels.combat.dps") }}</div>
          <div class="tile__value">
            {{ toNumber(round(stats.dps.total), "integer") }}
            <span class="tile__unit">DPS</span>
          </div>
          <div class="tile__sub">{{ t("labels.combat.dpsSub") }}</div>
        </div>
        <div class="tile">
          <div class="tile__label">{{ t("labels.combat.alpha") }}</div>
          <div class="tile__value">
            {{ toNumber(round(stats.alpha.total), "integer") }}
            <span class="tile__unit">DMG</span>
          </div>
          <div class="tile__sub">{{ t("labels.combat.alphaSub") }}</div>
        </div>
        <div class="tile">
          <div class="tile__label">{{ t("labels.combat.weapons") }}</div>
          <div class="tile__value">
            {{ toNumber(stats.weaponCount, "integer") }}
          </div>
        </div>
      </div>

      <div class="combat-panel__section-label">
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
        <div class="combat-panel__divider" />
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

      <div class="combat-panel__footer">
        <button
          type="button"
          class="combat-panel__toggle"
          @click="expanded = !expanded"
        >
          {{
            expanded
              ? t("labels.combat.hideBreakdown")
              : t("labels.combat.showBreakdown")
          }}
        </button>
        <span class="combat-panel__hint">{{ t("labels.combat.hint") }}</span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
$c-physical: $text-color;
$c-energy: $primary;
$c-distortion: $cyan;
$c-thermal: $warning;

.combat-panel {
  position: relative;
  margin: 15px 0 40px;
  background: $panel-bg;
  border: 2px solid rgba($gray-light, 0.5);
  border-radius: 16px;
  box-shadow: 0 6px 18px -12px rgba(#000, 0.8);

  &::before,
  &::after {
    content: "";
    position: absolute;
    left: 34px;
    right: 34px;
    height: 3px;
    background: #4a4f54;
    border-radius: 1px;
  }

  &::before {
    top: -2px;
  }

  &::after {
    bottom: -2px;
  }

  &__head {
    padding: 16px 18px 12px;
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 11px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 15px;
    letter-spacing: 0.2em;
    text-transform: uppercase;
    color: lighten($text-color, 15%);
  }

  &__dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: $gold;
    box-shadow: 0 0 10px 1px rgba($gold, 0.55);
  }

  &__body {
    padding: 4px 18px 18px;
  }

  &__hero {
    display: grid;
    grid-template-columns: 1.5fr 1fr 1fr;
    gap: 1px;
    background: rgba($gray-light, 0.28);
    border: 1px solid rgba($gray-light, 0.28);
    border-radius: 8px;
    overflow: hidden;
    margin-bottom: 20px;

    @media (max-width: 576px) {
      grid-template-columns: 1fr 1fr;
    }
  }

  &__section-label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: $gray-light;
    margin: 4px 0 10px;
  }

  &__divider {
    height: 1px;
    background: rgba($gray-light, 0.28);
    margin: 20px 0;
  }

  &__footer {
    display: flex;
    align-items: center;
    gap: 14px;
    margin-top: 16px;
    flex-wrap: wrap;
  }

  &__toggle {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    padding: 6px 13px;
    background: transparent;
    color: $text-color;
    border: 1px solid rgba($gray-light, 0.5);
    border-radius: 999px;
    cursor: pointer;
    transition: all 0.15s ease;

    &:hover {
      color: lighten($text-color, 15%);
      border-color: $primary;
    }
  }

  &__hint {
    font-size: 11.5px;
    color: $gray;
  }
}

.tile {
  position: relative;
  background: $gray-black;
  padding: 14px 16px;

  &--primary {
    grid-column: 1;

    @media (max-width: 576px) {
      grid-column: 1 / -1;
    }

    &::after {
      content: "";
      position: absolute;
      left: 0;
      top: 12px;
      bottom: 12px;
      width: 3px;
      background: linear-gradient($gold, rgba($gold, 0.15));
      border-radius: 2px;
    }
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: $gray-light;
    margin-bottom: 7px;
  }

  &__value {
    display: flex;
    align-items: baseline;
    gap: 6px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 700;
    font-size: 24px;
    line-height: 1;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &--primary &__value {
    font-size: 40px;
    color: #fff;

    @media (max-width: 576px) {
      font-size: 32px;
    }
  }

  &__unit {
    font-family: "Open Sans", sans-serif;
    font-weight: 600;
    font-size: 12px;
    letter-spacing: 0.08em;
    color: $gray-light;
  }

  &__sub {
    margin-top: 6px;
    font-size: 11px;
    color: $gray;
  }
}

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
