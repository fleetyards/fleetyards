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

// FontAwesome fallback for families without a hardpoint SVG (mirroring the
// glyphs the Hardpoints view uses).
const FAMILY_FA_ICON: Partial<Record<PowerFamily, string>> = {
  lifeSupport: "fa-star-of-life",
  salvage: "fa-bin-recycle",
  miningLaser: "fa-gem",
  tractorBeam: "fa-magnet",
  towingbeam: "fa-link",
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

// Set a column toward `desired` segments, honoring the rules: a component is
// off (0) or on at ≥ its mandatory floor, and an increase can't exceed the pips
// available in the pool (so clicking with an empty pool does nothing).
const applyTarget = (column: PowerColumn, desired: number) => {
  let target = Math.max(0, Math.min(column.capacity, desired));
  if (target > 0 && target < column.min) target = 0;

  if (target > column.allocated) {
    const available = sim.value.remaining;
    if (column.allocated === 0) {
      if (available < column.min) return; // can't afford to turn it on
      target = Math.min(target, available);
    } else {
      target = Math.min(target, column.allocated + available);
    }
  }

  if (target === column.allocated) return;
  emit("update:modelValue", { ...props.modelValue, [column.portPath]: target });
};

// Click pip cell at `level` (bottom-up): allocate exactly that many segments —
// click a lower pip to reduce, the same pip does nothing. (Turn fully off via
// the icon.)
const setLevel = (column: PowerColumn, level: number) =>
  applyTarget(column, level);

// Click the icon: drain the column to 0 if it has any pips, else fill it from
// the pool — erkul's icon toggle.
const toggleColumn = (column: PowerColumn) =>
  applyTarget(column, column.allocated > 0 ? 0 : column.capacity);

const reset = () => emit("update:modelValue", {});

// Hover preview: while hovering a pip, the column renders as if allocated to the
// hovered level (fills up going higher, empties going lower) so the click result
// is visible before committing.
const hoveredPort = ref<string | null>(null);
const hoveredLevel = ref(0);
const onPipHover = (column: PowerColumn, level: number) => {
  hoveredPort.value = column.portPath;
  hoveredLevel.value = level;
};
const clearHover = () => {
  hoveredPort.value = null;
};
const shownLevel = (column: PowerColumn) =>
  hoveredPort.value === column.portPath ? hoveredLevel.value : column.allocated;

// Pip cells for a column: the mandatory floor renders as one taller block, then
// each optional segment as its own cell. `level` is the allocation this cell
// represents (its top).
const cells = (column: PowerColumn) => {
  const list: { level: number; span: number }[] = [];
  if (column.min > 0) list.push({ level: column.min, span: column.min });
  for (let level = column.min + 1; level <= column.capacity; level += 1) {
    list.push({ level, span: 1 });
  }
  return list;
};

const PIP_HEIGHT = 9;
const PIP_GAP = 2;
const cellHeight = (span: number) =>
  `${span * PIP_HEIGHT + (span - 1) * PIP_GAP}px`;
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
            v-for="cell in cells(column)"
            :key="cell.level"
            type="button"
            class="power-col__pip"
            :class="{
              'power-col__pip--on': cell.level <= shownLevel(column),
              'power-col__pip--top': cell.level === shownLevel(column),
              'power-col__pip--block': cell.span > 1,
              'power-col__pip--preview': hoveredPort === column.portPath,
            }"
            :style="{ height: cellHeight(cell.span) }"
            :aria-label="`${columnLabel(column)}: ${cell.level}`"
            @mouseenter="onPipHover(column, cell.level)"
            @focus="onPipHover(column, cell.level)"
            @mouseleave="clearHover"
            @blur="clearHover"
            @click="setLevel(column, cell.level)"
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
          <i
            v-else-if="FAMILY_FA_ICON[column.family]"
            class="fa-duotone power-col__fa"
            :class="FAMILY_FA_ICON[column.family]"
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
  justify-content: space-between;
  gap: 6px;
  min-height: 180px;
  overflow-x: auto;
}

.power-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1 1 0;
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
    width: 100%;
    max-width: 44px;
  }

  &__pip {
    height: 9px;
    border: 0;
    border-radius: 2px;
    background: rgba($gray-light, 0.18);
    cursor: pointer;
    padding: 0;
    transition: background 0.1s ease;

    // Ordered so on/top override the preview tint (later rule wins).
    &--preview {
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

  &__fa {
    font-size: 13px;
    color: $gray;
    opacity: 0.85;
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
