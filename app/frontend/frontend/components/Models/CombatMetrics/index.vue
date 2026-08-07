<script lang="ts">
export default {
  name: "ModelCombatMetrics",
};
</script>

<script lang="ts" setup>
import type { Hardpoint } from "@/services/fyApi";
import Collapsed from "@/shared/components/Collapsed.vue";
import CompositionBar from "@/frontend/components/Models/CompositionBar/index.vue";
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

const damageTypes: {
  key: keyof DamageBreakdown;
  label: string;
  color: string;
}[] = [
  { key: "physical", label: "labels.combat.damagePhysical", color: "#c8c8c8" },
  { key: "energy", label: "labels.combat.damageEnergy", color: "#428bca" },
  {
    key: "distortion",
    label: "labels.combat.damageDistortion",
    color: "#38bec9",
  },
  { key: "thermal", label: "labels.combat.damageThermal", color: "#fa6800" },
];

const composition = computed(() =>
  damageTypes
    .map(({ key, label, color }) => ({
      key,
      label,
      color,
      value: stats.value.dps[key],
    }))
    .filter((entry) => entry.value > 0)
    .sort((a, b) => b.value - a.value),
);

const damageMeta = Object.fromEntries(
  damageTypes.map((entry) => [entry.key, entry]),
);
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
          <div class="metrics-card__tile__label">
            {{ t("labels.combat.dps") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(stats.dps.total), "integer") }}
            <span class="metrics-card__tile__unit">DPS</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.combat.dpsSub") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.combat.alpha") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(round(stats.alpha.total), "integer") }}
            <span class="metrics-card__tile__unit">DMG</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.combat.alphaSub") }}
          </div>
        </div>
        <div class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.combat.weapons") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(stats.weaponCount, "integer") }}
          </div>
        </div>
      </div>

      <div class="metrics-card__section-label">
        {{ t("labels.combat.composition") }}
      </div>
      <CompositionBar
        :segments="composition"
        :highlighted="hoveredType"
        @highlight="hoveredType = $event"
      />

      <div class="metrics-card__actions">
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
      </div>

      <Collapsed :visible="expanded" :duration="200">
        <div class="metrics-card__breakdown">
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
                <td class="weapon-table__name">
                  <span
                    class="weapon-table__type"
                    :style="{ background: damageMeta[weapon.type]?.color }"
                    :title="t(damageMeta[weapon.type]?.label)"
                  />
                  {{ weapon.name }}
                </td>
                <td class="num">
                  <span v-if="weapon.size">S{{ weapon.size }}</span>
                  <span v-else>—</span>
                </td>
                <td class="num">
                  {{ toNumber(round(weapon.dps), "integer") }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </Collapsed>

      <div class="metrics-card__footer">
        <span class="metrics-card__hint">{{ t("labels.combat.hint") }}</span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

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

  &__type {
    display: inline-block;
    width: 8px;
    height: 8px;
    margin-right: 8px;
    border-radius: 2px;
    vertical-align: middle;
  }
}
</style>
