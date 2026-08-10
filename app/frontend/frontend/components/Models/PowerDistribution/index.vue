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
  type FamilyOverrides,
} from "@/frontend/composables/useLoadoutSim";
import {
  POWER_FAMILIES,
  type FlightMode,
  type PowerFamily,
} from "@/frontend/composables/powerSim";

type Props = {
  hardpoints?: Hardpoint[];
  weaponPoolSize?: number;
  modelValue?: FamilyOverrides;
  mode?: FlightMode;
};

const props = withDefaults(defineProps<Props>(), {
  hardpoints: () => [],
  weaponPoolSize: undefined,
  modelValue: () => ({}),
  mode: "SCM",
});

const emit = defineEmits<{
  "update:modelValue": [value: FamilyOverrides];
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

const families = computed(() =>
  POWER_FAMILIES.filter((family) => sim.value.familyCapacity[family] > 0).map(
    (family) => ({
      family,
      label: t(`labels.power.families.${family}`),
      short: SHORT_LABEL[family],
      allocated: sim.value.perFamily[family],
      capacity: sim.value.familyCapacity[family],
    }),
  ),
);

const usedSegments = computed(
  () => sim.value.totalSegments - sim.value.remaining,
);

const hasOverrides = computed(() => Object.keys(props.modelValue).length > 0);

// Click pip cell at `level` (1-based, bottom-up): jump the family to that level,
// or step it down one when clicking the current top cell (so weapons can reach 0).
const setLevel = (family: PowerFamily, level: number) => {
  const current = sim.value.perFamily[family];
  const capacity = sim.value.familyCapacity[family];
  const target = Math.max(
    0,
    Math.min(capacity, level === current ? level - 1 : level),
  );
  emit("update:modelValue", { ...props.modelValue, [family]: target });
};

const reset = () => emit("update:modelValue", {});
</script>

<template>
  <MetricsCard
    v-if="families.length && sim.totalSegments > 0"
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
        v-for="entry in families"
        :key="entry.family"
        class="power-col"
        :class="{ 'power-col--weapon': entry.family === 'weapon' }"
      >
        <div class="power-col__count">{{ entry.allocated }}</div>
        <div
          class="power-col__stack"
          role="slider"
          :aria-label="entry.label"
          :aria-valuenow="entry.allocated"
          :aria-valuemin="0"
          :aria-valuemax="entry.capacity"
        >
          <button
            v-for="level in entry.capacity"
            :key="level"
            type="button"
            class="power-col__pip"
            :class="{
              'power-col__pip--on': level <= entry.allocated,
              'power-col__pip--top': level === entry.allocated,
            }"
            :aria-label="`${entry.label}: ${level}`"
            @click="setLevel(entry.family, level)"
          />
        </div>
        <div class="power-col__label" :title="entry.label">
          {{ entry.short }}
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
  justify-content: space-between;
  gap: 8px;
  min-height: 180px;
  overflow-x: auto;
}

.power-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1 1 0;
  min-width: 34px;
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
    width: 100%;
    max-width: 40px;
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
