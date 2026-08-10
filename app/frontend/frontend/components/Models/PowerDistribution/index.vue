<script lang="ts">
export default {
  name: "ModelPowerDistribution",
};
</script>

<script lang="ts" setup>
import type { Hardpoint } from "@/services/fyApi";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useLoadoutSim,
  type PortOverrides,
  type PowerColumn,
} from "@/frontend/composables/useLoadoutSim";
import {
  type FlightMode,
  type PowerFamily,
} from "@/frontend/composables/powerSim";
import weaponsIconUrl from "@/images/hardpoints/weapons.svg";
import shieldGeneratorsIconUrl from "@/images/hardpoints/shield_generators.svg";
import coolersIconUrl from "@/images/hardpoints/coolers.svg";
import radarIconUrl from "@/images/hardpoints/radar.svg";
import quantumDrivesIconUrl from "@/images/hardpoints/quantum_drives.svg";
import qedIconUrl from "@/images/hardpoints/qed.svg";
import empIconUrl from "@/images/hardpoints/emp.svg";
import mainThrustersIconUrl from "@/images/hardpoints/main_thrusters.svg";

type Props = {
  hardpoints?: Hardpoint[];
  weaponPoolSize?: number;
  modelValue?: PortOverrides;
  mode?: FlightMode;
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
  weaponPoolSize: undefined,
  modelValue: () => ({}),
  mode: "SCM",
});

const emit = defineEmits<{
  "update:modelValue": [value: PortOverrides];
  "update:mode": [value: FlightMode];
}>();

const { t } = useI18n();

// The hardpoint icon per family (engine falls back to the thruster glyph); a
// short text label covers families without a dedicated icon.
const FAMILY_ICON: Partial<Record<PowerFamily, string>> = {
  weapon: weaponsIconUrl,
  shield: shieldGeneratorsIconUrl,
  coolers: coolersIconUrl,
  radar: radarIconUrl,
  qdrive: quantumDrivesIconUrl,
  qed: qedIconUrl,
  emp: empIconUrl,
  engine: mainThrustersIconUrl,
};

const SHORT_LABEL: Record<PowerFamily, string> = {
  weapon: "WPN",
  engine: "ENG",
  shield: "SHD",
  qdrive: "QD",
  radar: "RAD",
  lifeSupport: "LS",
  coolers: "COOL",
  qed: "QED",
  emp: "EMP",
  miningLaser: "MIN",
  salvage: "SLV",
  tractorBeam: "TRC",
  towingbeam: "TOW",
};

const sim = useLoadoutSim(
  () => props.hardpoints,
  () => props.weaponPoolSize,
  () => props.mode,
  () => props.modelValue,
);

const columns = computed(() => sim.value.columns);
const usedSegments = computed(
  () => sim.value.totalSegments - sim.value.remaining,
);
const hasOverrides = computed(() => Object.keys(props.modelValue).length > 0);

const columnLabel = (column: PowerColumn) =>
  column.label ?? t(`labels.power.families.${column.family}`);

// Click pip cell at `level` (1-based, bottom-up): jump the component to that
// level, or step it down one when clicking the current top cell. A component is
// either off (0) or on at ≥ its mandatory floor, so a target below the floor
// snaps to off (turning all-critical systems like the QD into an on/off toggle).
const setLevel = (column: PowerColumn, level: number) => {
  let target = level === column.allocated ? level - 1 : level;
  if (target > 0 && target < column.min) target = 0;
  target = Math.max(0, Math.min(column.capacity, target));
  emit("update:modelValue", { ...props.modelValue, [column.portPath]: target });
};

// Click the icon: drain the column to 0 if it has any pips, else fill it up
// (bounded by the available pool) — erkul's icon toggle.
const toggleColumn = (column: PowerColumn) => {
  const target = column.allocated > 0 ? 0 : column.capacity;
  emit("update:modelValue", { ...props.modelValue, [column.portPath]: target });
};

const reset = () => emit("update:modelValue", {});
</script>

<template>
  <MetricsCard
    v-if="columns.length && sim.totalSegments > 0"
    :title="t('labels.power.title')"
    class="power-panel"
  >
    <div class="power-panel__toolbar">
      <div
        class="power-panel__seg"
        role="tablist"
        :aria-label="t('labels.power.title')"
      >
        <button
          v-for="flightMode in ['SCM', 'NAV'] as FlightMode[]"
          :key="flightMode"
          type="button"
          class="power-panel__seg-btn"
          :class="{ 'power-panel__seg-btn--active': mode === flightMode }"
          :aria-pressed="mode === flightMode"
          @click="emit('update:mode', flightMode)"
        >
          {{ t(`labels.power.${flightMode.toLowerCase()}`) }}
        </button>
      </div>
      <div class="power-panel__budget">
        {{
          t("labels.power.segmentsUsed", {
            used: usedSegments,
            total: sim.totalSegments,
          })
        }}
      </div>
    </div>

    <div class="power-bars">
      <div
        v-for="column in columns"
        :key="column.portPath"
        class="power-col"
        :class="{
          'power-col--weapon': column.family === 'weapon',
          'power-col--off': column.allocated === 0,
        }"
      >
        <div class="power-col__count">{{ column.allocated }}</div>
        <div
          class="power-col__stack"
          role="slider"
          :aria-label="columnLabel(column)"
          :aria-valuenow="column.allocated"
          :aria-valuemin="0"
          :aria-valuemax="column.capacity"
        >
          <button
            v-for="level in column.capacity"
            :key="level"
            type="button"
            class="power-col__pip"
            :class="{
              'power-col__pip--on': level <= column.allocated,
              'power-col__pip--top': level === column.allocated,
            }"
            :aria-label="`${columnLabel(column)}: ${level}`"
            @click="setLevel(column, level)"
          />
        </div>
        <button
          type="button"
          class="power-col__label"
          :title="columnLabel(column)"
          :aria-label="columnLabel(column)"
          @click="toggleColumn(column)"
        >
          <img
            v-if="FAMILY_ICON[column.family]"
            :src="FAMILY_ICON[column.family]"
            :alt="columnLabel(column)"
            class="power-col__icon"
          />
          <span v-else>{{ SHORT_LABEL[column.family] }}</span>
        </button>
      </div>
    </div>

    <div class="metrics-card__actions">
      <button
        type="button"
        class="metrics-card__toggle"
        :disabled="!hasOverrides"
        @click="reset"
      >
        {{ t("labels.power.reset") }}
      </button>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">{{ t("labels.power.hint") }}</span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

.power-panel {
  &__toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 18px;
  }

  &__seg {
    display: inline-flex;
    border: 1px solid rgba($gray-light, 0.28);
    border-radius: 4px;
    overflow: hidden;
  }

  &__seg-btn {
    padding: 5px 14px;
    background: transparent;
    border: 0;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray;
    cursor: pointer;

    &--active {
      background: rgba($primary, 0.18);
      color: $text-color;
    }
  }

  &__budget {
    font-size: 11px;
    letter-spacing: 0.08em;
    color: $gray;
    font-variant-numeric: tabular-nums;
  }
}

.power-bars {
  display: flex;
  align-items: flex-end;
  justify-content: flex-start;
  gap: 6px;
  min-height: 180px;
  overflow-x: auto;
}

.power-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 0 0 auto;
  min-width: 30px;
  gap: 6px;

  &__count {
    font-size: 13px;
    font-variant-numeric: tabular-nums;
    color: $text-color;
    min-height: 16px;
  }

  &__stack {
    display: flex;
    flex-direction: column-reverse;
    gap: 2px;
    width: 26px;
  }

  &__pip {
    height: 9px;
    border: 0;
    border-radius: 2px;
    background: rgba($gray-light, 0.18);
    cursor: pointer;
    padding: 0;
    transition: background 0.1s ease;

    &:hover {
      background: rgba($gray-light, 0.32);
    }

    &--on {
      background: rgba($primary, 0.4);
    }

    &--top {
      background: $primary;
    }
  }

  &--weapon &__pip--on {
    background: rgba(#fa6800, 0.45);
  }

  &--weapon &__pip--top {
    background: #fa6800;
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 8.5px;
    letter-spacing: 0.08em;
    color: $gray;
    text-transform: uppercase;
    height: 16px;
    display: flex;
    align-items: center;
    border: 0;
    background: transparent;
    padding: 0;
    cursor: pointer;
  }

  &__icon {
    width: 15px;
    height: 15px;
    opacity: 0.75;
  }

  // A column with no pips reads as "off" — dim its count and icon.
  &--off {
    .power-col__count {
      color: $gray;
      opacity: 0.5;
    }

    .power-col__icon {
      opacity: 0.3;
    }

    .power-col__label {
      opacity: 0.6;
    }
  }
}
</style>
