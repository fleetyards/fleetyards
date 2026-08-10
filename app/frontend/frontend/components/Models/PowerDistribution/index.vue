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

// Short column labels (erkul-style compact glyphs under each pip bar).
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
// level, or step it down one when clicking the current top cell.
const setLevel = (column: PowerColumn, level: number) => {
  const target = Math.max(
    0,
    Math.min(column.capacity, level === column.allocated ? level - 1 : level),
  );
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
        :class="{ 'power-col--weapon': column.family === 'weapon' }"
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
        <div class="power-col__label" :title="columnLabel(column)">
          {{ SHORT_LABEL[column.family] }}
        </div>
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
  }
}
</style>
