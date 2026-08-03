<script lang="ts">
export default {
  name: "ModelSurvivabilityMetrics",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import CompositionBar from "@/frontend/components/Models/CompositionBar/index.vue";
import type { Hardpoint, ModelMetricsHullPartsItem } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useShieldStats } from "@/frontend/composables/useShieldStats";
import { useLoadoutStats } from "@/frontend/composables/useLoadoutStats";

type Props = {
  hardpoints?: Hardpoint[];
  hullHealth?: number;
  hullParts?: ModelMetricsHullPartsItem[];
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
  hullHealth: undefined,
  hullParts: () => [],
});

const { t, toNumber } = useI18n();

const stats = useShieldStats(() => props.hardpoints);
const loadout = useLoadoutStats(() => props.hardpoints);

const round = (value: number) => Math.round(value);

const expanded = ref(false);
const hoveredCategory = ref<string | null>(null);

const hasHull = computed(() => (props.hullHealth ?? 0) > 0);
const hasData = computed(() => stats.value.hasData || hasHull.value);

// Combined survivability pool (shield HP + hull HP), and the resistance-adjusted
// effective HP against each hull-lethal damage type: shields absorb
// `1 / (1 - resistance)` more of that type before the hull is exposed. Distortion
// is excluded — it downs shields rather than destroying the hull.
const EHP_TYPES = [
  { key: "physical", label: "labels.survivability.resistancePhysical", color: "#c8c8c8" },
  { key: "energy", label: "labels.survivability.resistanceEnergy", color: "#428bca" },
  { key: "thermal", label: "labels.survivability.resistanceThermal", color: "#fa6800" },
];

const combinedHp = computed(() => (props.hullHealth ?? 0) + stats.value.totalHp);

const effectiveHp = computed(() => {
  if (combinedHp.value <= 0) return [];

  const hull = props.hullHealth ?? 0;
  const shield = stats.value.totalHp;
  const resistance = Object.fromEntries(
    stats.value.resistances.map((entry) => [entry.key, entry.value]),
  );

  return EHP_TYPES.map(({ key, label, color }) => {
    const value = Math.min(resistance[key] ?? 0, 0.95);
    return { key, label, color, value: hull + shield / (1 - value) };
  });
});

// Mirror-match estimate: seconds for an identical ship's own burst DPS to chew
// through the combined HP pool. Ignores shield regen and resistances — a rough
// "how tanky" figure, not a duel simulation.
const ttk = computed(() => {
  const dps = loadout.value.dps.total;
  if (dps <= 0 || combinedHp.value <= 0) return null;

  return combinedHp.value / dps;
});

const CATEGORY_ORDER = ["vital", "secondary", "breakable", "subpart"] as const;

const CATEGORY_COLORS: Record<string, string> = {
  vital: "#d76a6a",
  secondary: "#c67c7a",
  breakable: "#b18e8d",
  subpart: "#96898a",
};

const partGroups = computed(() =>
  CATEGORY_ORDER.map((category) => {
    const parts = props.hullParts
      .filter((part) => part.category === category)
      .sort((a, b) => b.health - a.health);

    return {
      category,
      label: `labels.survivability.category.${category}`,
      parts,
      total: parts.reduce((sum, part) => sum + part.health, 0),
    };
  }).filter((group) => group.parts.length > 0),
);

const hullComposition = computed(() =>
  partGroups.value.map((group) => ({
    key: group.category,
    label: group.label,
    value: group.total,
    color: CATEGORY_COLORS[group.category],
  })),
);

const humanizePart = (name: string) =>
  name
    .replace(/^(dbr|lg)_/, "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
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
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">
            {{ t("labels.survivability.totalHp") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(combinedHp), "integer") }}
            <span class="metrics-card__tile__unit">HP</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.survivability.totalHpSub") }}
          </div>
        </div>
        <div v-if="stats.hasData" class="metrics-card__tile">
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
        <div v-if="hasHull" class="metrics-card__tile">
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

      <div v-if="ttk" class="ttk">
        <span class="ttk__label">{{ t("labels.survivability.ttk") }}</span>
        <span class="ttk__value">~{{ toNumber(round(ttk), "integer") }}s</span>
        <span class="ttk__note">{{ t("labels.survivability.ttkSub") }}</span>
      </div>

      <template v-if="effectiveHp.length">
        <div class="metrics-card__section-label">
          {{ t("labels.survivability.effectiveHp") }}
        </div>
        <div class="ehp">
          <div v-for="entry in effectiveHp" :key="entry.key" class="ehp__item">
            <span class="ehp__swatch" :style="{ background: entry.color }" />
            <span class="ehp__label">{{ t(entry.label) }}</span>
            <span class="ehp__value">
              {{ toNumber(round(entry.value), "integer") }}
            </span>
          </div>
        </div>
      </template>

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

      <template v-if="hullComposition.length">
        <div class="metrics-card__section-label">
          {{ t("labels.survivability.hullComposition") }}
        </div>
        <CompositionBar
          :segments="hullComposition"
          :highlighted="hoveredCategory"
          @highlight="hoveredCategory = $event"
        />
      </template>

      <div v-if="hullParts.length" class="metrics-card__actions">
        <button
          type="button"
          class="metrics-card__toggle"
          @click="expanded = !expanded"
        >
          {{
            expanded
              ? t("labels.survivability.hideParts")
              : t("labels.survivability.showParts")
          }}
        </button>
      </div>

      <Collapsed :visible="expanded" :duration="200">
        <div class="metrics-card__breakdown">
          <div
            v-for="group in partGroups"
            :key="group.category"
            class="hull-group"
            @mouseenter="hoveredCategory = group.category"
            @mouseleave="hoveredCategory = null"
          >
            <div class="hull-group__header">
              <span class="hull-group__label">
                <span
                  class="hull-group__swatch"
                  :style="{ background: CATEGORY_COLORS[group.category] }"
                />
                {{ t(group.label) }}
              </span>
              <span class="hull-group__meta">
                {{ group.parts.length }} ·
                {{ toNumber(round(group.total), "integer") }} HP
              </span>
            </div>
            <table class="hull-table">
              <tbody>
                <tr v-for="part in group.parts" :key="part.name">
                  <td class="hull-table__name">
                    {{ humanizePart(part.name) }}
                  </td>
                  <td class="num">
                    {{ toNumber(round(part.health), "integer") }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </Collapsed>

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

.ttk {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin-bottom: 20px;
  padding: 10px 12px;
  background: $gray-black;
  border: 1px solid rgba($gray-light, 0.28);
  border-radius: 6px;

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: $gray-light;
  }

  &__value {
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 700;
    font-size: 16px;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &__note {
    margin-left: auto;
    font-size: 11px;
    color: $gray;
  }

  @media (max-width: 576px) {
    flex-wrap: wrap;

    &__note {
      margin-left: 0;
    }
  }
}

.ehp {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  margin-bottom: 20px;

  @media (max-width: 576px) {
    grid-template-columns: 1fr;
  }

  &__item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 10px;
    background: $gray-black;
    border: 1px solid rgba($gray-light, 0.28);
    border-radius: 6px;
  }

  &__swatch {
    width: 8px;
    height: 8px;
    border-radius: 2px;
    flex: none;
  }

  &__label {
    font-size: 12px;
    color: $gray-light;
    flex: 1;
  }

  &__value {
    font-weight: 700;
    font-size: 13px;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }
}

.resist {
  display: grid;
  gap: 10px;
  margin-bottom: 20px;

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

.hull-group {
  margin-bottom: 14px;

  &:last-child {
    margin-bottom: 0;
  }

  &__header {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 4px;
    padding-bottom: 4px;
    border-bottom: 1px solid rgba($gray-light, 0.28);
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: lighten($text-color, 10%);
  }

  &__swatch {
    display: inline-block;
    width: 8px;
    height: 8px;
    margin-right: 8px;
    border-radius: 2px;
    vertical-align: middle;
  }

  &__meta {
    font-size: 11px;
    color: $gray-light;
    font-variant-numeric: tabular-nums;
  }
}

.hull-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;

  td {
    padding: 9px 10px 9px 0;
    border-bottom: 1px solid rgba($gray-light, 0.28);
    color: $text-color;

    &:first-child {
      padding-left: 18px;
    }
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
