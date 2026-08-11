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
  type PowerColumnMember,
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
import utilityItemsIconUrl from "@/images/hardpoints/utility_items.svg";

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

const { t, toNumber } = useI18n();

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
  tractorBeam: utilityItemsIconUrl,
  towingbeam: utilityItemsIconUrl,
};

// FontAwesome fallback for families without a hardpoint SVG (mirroring the
// glyphs the Hardpoints view uses).
const FAMILY_FA_ICON: Partial<Record<PowerFamily, string>> = {
  lifeSupport: "fa-star-of-life",
  salvage: "fa-bin-recycle",
  miningLaser: "fa-gem",
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

// Aim-assist readout for the power pane: effective range + how full it is
// relative to the radar's max (grows as the radar gets more power).
const aimAssistPercent = computed(() =>
  sim.value.aimAssistMax > 0
    ? Math.round((sim.value.aimAssist / sim.value.aimAssistMax) * 100)
    : 0,
);

// Cooling load: heat generated as a share of the coolant the active coolers
// provide (erkul's coolingRatio). Can exceed 100% when the ship is under-cooled;
// 0 with no active cooler. Only shown when the ship actually has coolers.
const hasCoolers = computed(() => sim.value.coolingMaxPerSec > 0);
const coolingPercent = computed(() => Math.round(sim.value.coolingRatio * 100));
const coolingFill = computed(() => Math.min(coolingPercent.value, 100));
const coolingOver = computed(() => coolingPercent.value > 100);

const familyLabel = (family: PowerFamily) =>
  t(`labels.power.families.${family}`);
const columnLabel = (column: PowerColumn) =>
  column.members.length > 1
    ? familyLabel(column.family)
    : (column.label ?? familyLabel(column.family));
const memberLabel = (column: PowerColumn, member: PowerColumnMember) =>
  member.label ?? familyLabel(column.family);

// Set a member (a single component or the weapon pool) toward `desired`
// segments, honoring the rules: it is off (0) or on at ≥ its mandatory floor,
// and an increase can't exceed the pips available in the pool (so clicking with
// an empty pool does nothing).
const applyTarget = (member: PowerColumnMember, desired: number) => {
  let target = Math.max(0, Math.min(member.fillable, desired));
  if (target > 0 && target < member.min) target = 0;

  if (target > member.allocated) {
    const available = sim.value.remaining;
    if (member.allocated === 0) {
      if (available < member.min) return; // can't afford to turn it on
      target = Math.min(target, available);
    } else {
      target = Math.min(target, member.allocated + available);
    }
  }

  if (target === member.allocated) return;
  emit("update:modelValue", { ...props.modelValue, [member.portPath]: target });
};

// Click a pip cell at `level` (bottom-up). In a stacked column the merged base
// block sets that generator/beam to its minimum, or toggles it off when it is
// already at the minimum — so a member with headroom (e.g. 4 + 1) can still be
// reduced to 4 or switched off without jumping straight to full. Every other
// pip allocates exactly `level` segments to that member.
const onCellClick = (
  column: PowerColumn,
  member: PowerColumnMember,
  level: number,
) => {
  if (level > member.fillable) return; // headroom slot — not fillable
  if (column.members.length > 1 && level === member.min) {
    applyTarget(member, member.allocated === member.min ? 0 : member.min);
  } else {
    applyTarget(member, level);
  }
};

// Click the icon: drain the whole column to 0 if any member has pips, else fill
// every member from the pool — erkul's icon toggle.
const toggleColumn = (column: PowerColumn) => {
  const anyOn = column.members.some((member) => member.allocated > 0);
  const next: PortOverrides = { ...props.modelValue };
  for (const member of column.members) {
    next[member.portPath] = anyOn ? 0 : member.fillable;
  }
  emit("update:modelValue", next);
};

const reset = () => emit("update:modelValue", {});

// Hover preview: while hovering a pip, the member renders as if allocated to the
// hovered level (fills up going higher, empties going lower) so the click result
// is visible before committing.
const hoveredPort = ref<string | null>(null);
const hoveredLevel = ref(0);
const onPipHover = (member: PowerColumnMember, level: number) => {
  if (level > member.fillable) return; // don't preview unfillable headroom
  hoveredPort.value = member.portPath;
  hoveredLevel.value = level;
};
const clearHover = () => {
  hoveredPort.value = null;
};
const shownLevel = (member: PowerColumnMember) =>
  hoveredPort.value === member.portPath ? hoveredLevel.value : member.allocated;

// Pip cells for a member: the mandatory floor renders as one taller block, then
// each optional segment as its own cell. `level` is the allocation this cell
// represents (its top).
const cells = (member: PowerColumnMember) => {
  const list: { level: number; span: number }[] = [];
  if (member.min > 0) list.push({ level: member.min, span: member.min });
  for (let level = member.min + 1; level <= member.capacity; level += 1) {
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

    <div
      v-if="hasCoolers"
      class="power-readout"
      :class="{ 'power-readout--over': coolingOver }"
    >
      <span class="power-readout__label">{{ t("labels.power.cooling") }}</span>
      <div class="power-readout__track">
        <div
          class="power-readout__fill"
          :style="{ width: `${coolingFill}%` }"
        />
      </div>
      <span class="power-readout__value">{{ coolingPercent }}%</span>
    </div>

    <div v-if="sim.aimAssistMax > 0" class="power-readout">
      <span class="power-readout__label">{{
        t("labels.power.aimAssist")
      }}</span>
      <div class="power-readout__track">
        <div
          class="power-readout__fill"
          :style="{ width: `${aimAssistPercent}%` }"
        />
      </div>
      <span class="power-readout__value">
        {{ sim.aimAssist ? toNumber(sim.aimAssist, "integer") : 0 }} m
      </span>
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
        <div class="power-col__count">
          {{ column.allocated }} / {{ column.capacity }}
        </div>
        <div
          class="power-col__stack"
          role="group"
          :aria-label="columnLabel(column)"
        >
          <template
            v-for="(member, memberIndex) in column.members"
            :key="member.portPath"
          >
            <div
              v-if="memberIndex > 0"
              class="power-col__divider"
              aria-hidden="true"
            />
            <button
              v-for="cell in cells(member)"
              :key="`${member.portPath}-${cell.level}`"
              type="button"
              class="power-col__pip"
              :class="{
                'power-col__pip--on': cell.level <= shownLevel(member),
                'power-col__pip--top': cell.level === shownLevel(member),
                'power-col__pip--block': cell.span > 1,
                'power-col__pip--preview': hoveredPort === member.portPath,
                'power-col__pip--headroom': cell.level > member.fillable,
                'power-col__pip--memberoff':
                  column.members.length > 1 && member.allocated === 0,
              }"
              :style="{ height: cellHeight(cell.span) }"
              :title="memberLabel(column, member)"
              :aria-label="`${memberLabel(column, member)}: ${cell.level}`"
              @mouseenter="onPipHover(member, cell.level)"
              @focus="onPipHover(member, cell.level)"
              @mouseleave="clearHover"
              @blur="clearHover"
              @click="onCellClick(column, member, cell.level)"
            >
              <span v-if="cell.span > 1" class="power-col__pip-label">{{
                cell.span
              }}</span>
            </button>
          </template>
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

.power-readout {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 16px;

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 9.5px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray;
    min-width: 76px;
  }

  &__track {
    flex: 1;
    height: 8px;
    border-radius: 999px;
    overflow: hidden;
    background: $gray-black;
    border: 1px solid rgba($gray-light, 0.28);
  }

  &__fill {
    height: 100%;
    background: $primary;
    border-radius: 999px;
    transition: width 0.4s ease;
  }

  &__value {
    font-size: 12px;
    color: $text-color;
    font-variant-numeric: tabular-nums;
    min-width: 64px;
    text-align: right;
  }

  // Under-cooled: heat load exceeds the coolers' output.
  &--over &__fill {
    background: $danger;
  }

  &--over &__value {
    color: $danger;
  }
}

.power-bars {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 14px 10px;
  min-height: 170px;
  overflow-x: auto;
}

.power-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1 1 0;
  min-width: 34px;
  max-width: 72px;
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
    display: flex;
    align-items: center;
    justify-content: center;
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

    // A generator/beam turned off inside a stacked column reads as empty.
    &--memberoff {
      background: rgba($gray-light, 0.1);
    }

    // Weapon-pool headroom: shown for scale but not fillable.
    &--headroom {
      background: transparent;
      border: 1px solid rgba($gray-light, 0.16);
      cursor: not-allowed;
    }
  }

  // erkul-style count inside a merged (span > 1) block.
  &__pip-label {
    font-size: 11px;
    font-weight: 600;
    line-height: 1;
    color: $text-color;
    font-variant-numeric: tabular-nums;
    pointer-events: none;
  }

  // Separates the stacked members (generators / beams) of a grouped column.
  &__divider {
    height: 0;
    margin: 1px 0;
    border-top: 1px dashed rgba($gray-light, 0.35);
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
    opacity: 1;
  }

  &__fa {
    font-size: 13px;
    color: $primary;
    opacity: 1;
  }

  // A column with no pips reads as "off" — dim its count and icon. A powered
  // column (any pip, including a single critical one) stays at full strength.
  &--off {
    .power-col__count {
      color: $gray;
      opacity: 0.5;
    }

    .power-col__icon {
      opacity: 0.3;
    }

    .power-col__fa {
      color: $gray;
      opacity: 0.4;
    }

    .power-col__label {
      opacity: 0.6;
    }
  }
}
</style>
