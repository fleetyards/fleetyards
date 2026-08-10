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
      allocated: sim.value.perFamily[family],
      capacity: sim.value.familyCapacity[family],
    }),
  ),
);

const usedSegments = computed(
  () => sim.value.totalSegments - sim.value.remaining,
);

const hasOverrides = computed(() => Object.keys(props.modelValue).length > 0);

const setTarget = (family: PowerFamily, target: number) => {
  const capacity = sim.value.familyCapacity[family];
  const clamped = Math.max(0, Math.min(capacity, target));
  emit("update:modelValue", { ...props.modelValue, [family]: clamped });
};

const step = (family: PowerFamily, delta: number) => {
  setTarget(family, sim.value.perFamily[family] + delta);
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

    <ul class="power-panel__families">
      <li
        v-for="entry in families"
        :key="entry.family"
        class="power-family"
        :class="{ 'power-family--weapon': entry.family === 'weapon' }"
      >
        <div class="power-family__head">
          <span class="power-family__label">{{ entry.label }}</span>
          <span class="power-family__count">
            {{ entry.allocated
            }}<span class="power-family__count-max">/{{ entry.capacity }}</span>
          </span>
        </div>
        <div class="power-family__control">
          <button
            type="button"
            class="power-family__step"
            :disabled="entry.allocated <= 0"
            :aria-label="`- ${entry.label}`"
            @click="step(entry.family, -1)"
          >
            −
          </button>
          <div
            class="power-family__bar"
            role="progressbar"
            :aria-valuenow="entry.allocated"
            :aria-valuemax="entry.capacity"
          >
            <span
              v-for="n in entry.capacity"
              :key="n"
              class="power-family__pip"
              :class="{ 'power-family__pip--on': n <= entry.allocated }"
            />
          </div>
          <button
            type="button"
            class="power-family__step"
            :disabled="entry.allocated >= entry.capacity"
            :aria-label="`+ ${entry.label}`"
            @click="step(entry.family, 1)"
          >
            +
          </button>
        </div>
      </li>
    </ul>

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
    margin-bottom: 16px;
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

  &__families {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
}

.power-family {
  &__head {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    margin-bottom: 5px;
  }

  &__label {
    font-size: 12px;
    color: lighten($text-color, 15%);
  }

  &__count {
    font-size: 12px;
    font-variant-numeric: tabular-nums;
    color: $text-color;
  }

  &__count-max {
    color: $gray;
  }

  &__control {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  &__step {
    flex: 0 0 auto;
    width: 24px;
    height: 24px;
    border: 1px solid rgba($gray-light, 0.28);
    border-radius: 4px;
    background: transparent;
    color: $text-color;
    font-size: 15px;
    line-height: 1;
    cursor: pointer;

    &:disabled {
      opacity: 0.35;
      cursor: default;
    }
  }

  &__bar {
    flex: 1 1 auto;
    display: flex;
    gap: 2px;
    min-width: 0;
  }

  &__pip {
    flex: 1 1 0;
    height: 10px;
    border-radius: 2px;
    background: rgba($gray-light, 0.22);
    transition: background 0.12s ease;

    &--on {
      background: rgba($primary, 0.55);
    }
  }

  &--weapon .power-family__pip--on {
    background: rgba(#fa6800, 0.7);
  }
}
</style>
