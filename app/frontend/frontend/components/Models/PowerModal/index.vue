<script lang="ts">
export default {
  name: "PowerPlannerModal",
};
</script>

<script lang="ts" setup>
import {
  type ComponentPowerPlant,
  type Hardpoint,
  HardpointCategoryEnum,
  type ModelSignatureCrossSection,
} from "@/services/fyApi";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import ChipRow from "@/shared/components/base/Chip/Row/index.vue";
import Sortable from "sortablejs";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type PortOverrides,
  type PowerColumn,
  type PowerColumnMember,
  useLoadoutSim,
} from "@/frontend/composables/useLoadoutSim";
import {
  emptySplits,
  type FlightMode,
  type PowerSplits,
  type WeaponRegenModifier,
} from "@/frontend/composables/powerSim";
import {
  MAX_POWER_PRESETS,
  MAX_POWER_PRESET_NAME,
  type PowerPresets,
  presetFrom,
  presetMatches,
  presetSplits,
} from "@/frontend/composables/usePowerPresets";
import type { PowerPreset } from "@/services/fyApi";
import {
  capacitor,
  dutyCycle,
  useLoadoutStats,
} from "@/frontend/composables/useLoadoutStats";
import { computeShieldStats } from "@/frontend/composables/useShieldStats";
import {
  pipCells,
  pipClickTarget,
} from "@/frontend/components/Models/PowerDistribution/allocation";
import {
  type GunStack,
  weaponStations,
} from "@/frontend/components/Models/Hardpoints/weaponStations";

type Props = {
  modelName?: string;
  backdrop?: string;
  hardpoints: Hardpoint[];
  weaponPoolSize?: number;
  regenModifier?: WeaponRegenModifier;
  crossSection?: ModelSignatureCrossSection;
  // The power card's own pips and mode, so the planner opens on the split the
  // card shows and the card follows what is set here.
  splits?: PowerSplits;
  mode?: FlightMode;
  // A saved loadout's presets; none on a ship's own page.
  presets?: PowerPresets;
  onChange?: (splits: PowerSplits, mode: FlightMode) => void;
};

const props = withDefaults(defineProps<Props>(), {
  modelName: undefined,
  backdrop: undefined,
  weaponPoolSize: undefined,
  regenModifier: undefined,
  crossSection: undefined,
  splits: () => emptySplits(),
  mode: "SCM",
  presets: undefined,
  onChange: undefined,
});

// Both modes' splits: a preset keeps SCM and NAV together. The bars show and
// set the split of the mode the planner is in.
const splits = ref<PowerSplits>({ ...emptySplits(), ...props.splits });
const mode = ref<FlightMode>(props.mode);

const overrides = computed<PortOverrides>({
  get: () => splits.value[mode.value],
  set: (value) => {
    splits.value = { ...splits.value, [mode.value]: value };
  },
});

watch([splits, mode], () => props.onChange?.(splits.value, mode.value));

const sim = useLoadoutSim(
  () => props.hardpoints,
  () => props.weaponPoolSize,
  mode,
  overrides,
  undefined,
  () => props.regenModifier,
);
const stats = useLoadoutStats(
  () => props.hardpoints,
  () => props.weaponPoolSize,
  overrides,
  () => props.regenModifier,
  mode,
);

const { t, toNumber } = useI18n();

const num = (value?: number | null) => {
  if (value === undefined || value === null || !Number.isFinite(value)) {
    return "—";
  }
  if (value === 0) return "0";
  return String(
    toNumber(
      Math.abs(value) >= 10 ? Math.round(value) : Math.round(value * 10) / 10,
    ),
  );
};

const compact = (value?: number | null) => {
  if (!value) return "0";
  return value >= 1000 ? `${num(Math.round(value / 100) / 10)}k` : num(value);
};

const percent = (value?: number | null) =>
  value === undefined || value === null ? "—" : `${Math.round(value * 100)}%`;

const used = computed(() => sim.value.totalSegments - sim.value.remaining);

// The plants, stacked by part: two of the same plant read as one row of two.
const plants = computed(() => {
  const stacks = new Map<string, { hardpoint: Hardpoint; count: number }>();
  for (const hardpoint of props.hardpoints) {
    if (hardpoint.category !== HardpointCategoryEnum.POWERPLANT) continue;
    const key = hardpoint.component?.name || hardpoint.id;
    const existing = stacks.get(key);
    if (existing) existing.count += 1;
    else stacks.set(key, { hardpoint, count: 1 });
  }
  return [...stacks.entries()].map(([key, stack]) => ({
    key,
    name: stack.hardpoint.component?.name || "",
    count: stack.count,
    hardpoint: stack.hardpoint,
  }));
});

const plantSegments = (hardpoint: Hardpoint) =>
  (hardpoint.component?.typeData as ComponentPowerPlant | undefined)?.powerBase;

const pick = (
  column: PowerColumn,
  member: PowerColumnMember,
  level: number,
) => {
  const next = pipClickTarget(
    overrides.value,
    column,
    member,
    level,
    sim.value.remaining,
  );
  if (next) overrides.value = next;
};

const shield = computed(() =>
  computeShieldStats(props.hardpoints, sim.value.shieldPoolRatio),
);

// The hardpoint category whose icon stands for each family, as on the power
// card; the engine takes the main thruster's.
const FAMILY_CATEGORY: Partial<
  Record<PowerColumn["family"], HardpointCategoryEnum>
> = {
  weapon: HardpointCategoryEnum.WEAPONS,
  shield: HardpointCategoryEnum.SHIELDGENERATOR,
  coolers: HardpointCategoryEnum.COOLER,
  radar: HardpointCategoryEnum.RADAR,
  qdrive: HardpointCategoryEnum.QUANTUMDRIVE,
  qed: HardpointCategoryEnum.QUANTUMENFORCEMENTDEVICE,
  emp: HardpointCategoryEnum.EMP,
  engine: HardpointCategoryEnum.MAIN_THRUSTERS,
  lifeSupport: HardpointCategoryEnum.LIFESUPPORT,
  salvage: HardpointCategoryEnum.SALVAGEMUNCHING,
};

// One row per system. The simulation gives each cooler a column of its own,
// while two shield generators share one; on a page that reads system by
// system, every part of a family sits in the same row.
interface SystemRow {
  family: PowerColumn["family"];
  columns: PowerColumn[];
  allocated: number;
  capacity: number;
  min: number;
  parts: string;
}

const rows = computed<SystemRow[]>(() => {
  const byFamily = new Map<PowerColumn["family"], PowerColumn[]>();
  for (const column of sim.value.columns) {
    byFamily.set(column.family, [
      ...(byFamily.get(column.family) || []),
      column,
    ]);
  }

  return [...byFamily.entries()].map(([family, columns]) => ({
    family,
    columns,
    allocated: columns.reduce((total, column) => total + column.allocated, 0),
    capacity: columns.reduce((total, column) => total + column.capacity, 0),
    min: columns[0].min,
    parts: [
      ...new Set(
        columns
          .flatMap((column) => column.members.map((member) => member.label))
          .filter(Boolean),
      ),
    ].join(", "),
  }));
});

// The tallest bar in segments, which the pips are sized from.
const tallest = computed(() =>
  Math.max(1, ...rows.value.map((row) => row.capacity)),
);

const rowEffect = (row: SystemRow): [string, string?] => {
  const on = row.allocated > 0;

  switch (row.family) {
    case "weapon":
      return on
        ? [
            t("labels.power.planner.sustained", {
              dps: num(stats.value.sustainedDps.total),
            }),
            t("labels.power.planner.weaponPower", {
              percent: percent(stats.value.weaponPowerRatio),
            }),
          ]
        : [t("labels.power.planner.weaponsOff")];
    case "shield":
      return on
        ? [
            `${num(shield.value.totalHp)} HP`,
            t("labels.power.planner.regen", {
              regen: num(shield.value.totalRegen),
            }),
          ]
        : [t("labels.power.planner.shieldsDown")];
    case "engine":
      if (!sim.value.engineActive) {
        return [
          t("labels.power.planner.engineOff"),
          t("labels.power.planner.engineOffSub"),
        ];
      }
      // At its floor the engine flies but has nothing left for boost, which
      // "boosted handling 0%" said in a way nobody could read.
      return sim.value.enginePowerRatio > 0
        ? [
            t("labels.power.planner.boostedHandling", {
              percent: percent(sim.value.enginePowerRatio),
            }),
          ]
        : [
            t("labels.power.planner.engineBase"),
            t("labels.power.planner.engineBaseSub"),
          ];
    case "radar":
      return on
        ? [`${num(sim.value.aimAssist)} m`, t("labels.power.aimAssist")]
        : [t("labels.power.planner.radarOff")];
    case "coolers":
      return on
        ? [
            t("labels.power.planner.coolant", {
              rate: num(sim.value.coolingPerSec),
            }),
          ]
        : [t("labels.power.planner.noCooling")];
    case "qdrive":
      return on
        ? [t("labels.power.planner.ready")]
        : [
            t("labels.power.planner.off"),
            t("labels.power.planner.needsBlock", { min: row.min }),
          ];
    default:
      return [
        on ? t("labels.power.planner.powered") : t("labels.power.planner.off"),
      ];
  }
};

const coolingPercent = computed(() => Math.round(sim.value.coolingRatio * 100));

const AXES = ["x", "y", "z"] as const;
type Axis = (typeof AXES)[number];

const axisValue = (axis: Axis) =>
  (props.crossSection?.[axis] || 0) * sim.value.signatureModifiers.crossSection;

const axis = ref<Axis>(
  AXES.reduce((best, current) =>
    axisValue(current) > axisValue(best) ? current : best,
  ),
);
const cycleAxis = () => {
  axis.value = AXES[(AXES.indexOf(axis.value) + 1) % AXES.length];
};

// The energy guns' own ammo capacitors, turrets' included: the weapon pips
// decide how big each one is and how fast it refills, which is where
// sustained fire comes from.
const energyGuns = computed(() =>
  weaponStations(
    props.hardpoints,
    stats.value.weaponPowerRatio,
    props.regenModifier,
  )
    .flatMap((station) =>
      station.guns.map((gun) => ({ ...gun, count: gun.count * station.count })),
    )
    .filter((gun) => !gun.missile && gun.armed)
    .reduce<GunStack[]>((stacks, gun) => {
      const existing = stacks.find((entry) => entry.name === gun.name);
      if (existing) existing.count += gun.count;
      else stacks.push({ ...gun });
      return stacks;
    }, [])
    .map((gun) => {
      const ratio = stats.value.weaponPowerRatio;
      const shotsPerSecond = (gun.weapon.fireRate || 0) / 60;
      const cycle = dutyCycle(gun.weapon, ratio, props.regenModifier);
      const charge = capacitor(gun.weapon, ratio, props.regenModifier);

      if (charge) {
        return {
          ...gun,
          energy: true,
          capacity: charge.shots,
          // The most this ship's pool can give the gun, rather than the load
          // it would hold with the pool feeding it alone.
          capacityMax:
            capacitor(gun.weapon, sim.value.weaponMaxRatio, props.regenModifier)
              ?.shots ?? charge.shots,
          regen: charge.regenPerSecond,
          emptyIn: shotsPerSecond ? charge.shots / shotsPerSecond : 0,
          refillIn: cycle.offTime,
          share: cycle.ratio,
        };
      }

      const heat = gun.weapon.heat;
      return {
        ...gun,
        energy: false,
        capacity: 0,
        capacityMax: 0,
        regen: 0,
        emptyIn:
          heat?.overheatTemperature && gun.weapon.heatPerShot && shotsPerSecond
            ? heat.overheatTemperature /
              (gun.weapon.heatPerShot * shotsPerSecond)
            : 0,
        refillIn: heat?.overheatFixTime || 0,
        share: cycle.ratio,
      };
    }),
);

// The modal store makes its props deeply reactive, which unwraps the
// context's refs, so each is read whether or not it still is one.
const presetList = computed(() => toValue(props.presets?.presets) ?? []);
const presetsEditable = computed(() => !!toValue(props.presets?.editable));
const presetsSaving = computed(() => !!toValue(props.presets?.saving));

const sameName = (a: string, b: string) =>
  a.trim().toLowerCase() === b.trim().toLowerCase();

const applyPreset = (preset: PowerPreset) => {
  splits.value = presetSplits(preset);
};

const isApplied = (preset: PowerPreset) => presetMatches(preset, splits.value);

// Presets read as the hangar's group chips: a plus opens the name field, and
// the pen turns the row to editing, where a chip moves, and its edit control
// opens renaming and deleting.
const mobile = useMobile();
const adding = ref(false);
const editing = ref(false);
const newName = ref("");

const canAdd = computed(
  () => presetsEditable.value && presetList.value.length < MAX_POWER_PRESETS,
);

const startAdding = () => {
  renaming.value = null;
  adding.value = true;
};

// Saving under a name that is taken stores the current split in its place.
const canSave = computed(() => {
  const name = newName.value.trim();
  if (!name || name.length > MAX_POWER_PRESET_NAME || presetsSaving.value) {
    return false;
  }

  return (
    presetList.value.length < MAX_POWER_PRESETS ||
    presetList.value.some((preset) => sameName(preset.name, name))
  );
});

const saveCurrent = async () => {
  if (!props.presets || !canSave.value) return;

  const preset = presetFrom(newName.value.trim(), splits.value);
  const list = presetList.value.some((entry) =>
    sameName(entry.name, preset.name),
  )
    ? presetList.value.map((entry) =>
        sameName(entry.name, preset.name) ? preset : entry,
      )
    : [...presetList.value, preset];

  if (await props.presets.save(list)) {
    newName.value = "";
    adding.value = false;
  }
};

const renaming = ref<string | null>(null);
const renameTo = ref("");

const startRename = (preset: PowerPreset) => {
  adding.value = false;
  renaming.value = preset.name;
  renameTo.value = preset.name;
};

// Dragging by a chip's grip, as the hangar's group chips sort. Bound to the
// row's element, which the row swaps for a dropdown on a phone.
const row = ref<{ itemsEl: HTMLElement | null } | null>(null);
let sortable: Sortable | null = null;

const bindSortable = (container?: HTMLElement | null) => {
  sortable?.destroy();
  sortable = null;
  if (!container || !presetsEditable.value || !editing.value) return;

  sortable = Sortable.create(container, {
    animation: 150,
    handle: ".chip__handle",
    ghostClass: "chip--ghost",
    onEnd: () => {
      const order = Array.from(
        container.querySelectorAll("[data-preset-name]"),
      ).map((el) => el.getAttribute("data-preset-name"));
      const list = order
        .map((name) => presetList.value.find((preset) => preset.name === name))
        .filter((preset): preset is PowerPreset => !!preset);
      void props.presets?.save(list);
    },
  });
};

watch(
  [() => row.value?.itemsEl, presetsEditable, editing],
  ([container]) => bindSortable(container),
  { immediate: true, flush: "post" },
);

onUnmounted(() => sortable?.destroy());

const toggleEditing = () => {
  editing.value = !editing.value;
  if (!editing.value) renaming.value = null;
};

const movePreset = (preset: PowerPreset, offset: -1 | 1) => {
  const list = [...presetList.value];
  const from = list.indexOf(preset);
  const to = from + offset;
  if (from < 0 || to < 0 || to >= list.length) return;

  list.splice(to, 0, ...list.splice(from, 1));
  void props.presets?.save(list);
};

const renameValid = computed(() => {
  const name = renameTo.value.trim();

  return (
    !!name &&
    name.length <= MAX_POWER_PRESET_NAME &&
    !presetList.value.some(
      (preset) => preset.name !== renaming.value && sameName(preset.name, name),
    )
  );
});

const saveRename = async () => {
  if (!props.presets || !renameValid.value) return;

  const name = renameTo.value.trim();
  const list = presetList.value.map((preset) =>
    preset.name === renaming.value ? { ...preset, name } : preset,
  );

  if (await props.presets.save(list)) renaming.value = null;
};

const deletePreset = async () => {
  if (!props.presets) return;

  const list = presetList.value.filter(
    (entry) => entry.name !== renaming.value,
  );
  if (await props.presets.save(list)) renaming.value = null;
};

const seconds = (value: number) =>
  Number.isFinite(value) && value > 0 ? `${num(value)} s` : "—";
</script>

<template>
  <Modal
    :title="
      modelName
        ? t('labels.power.planner.titleFor', { name: modelName })
        : t('labels.power.planner.title')
    "
    fill-body
  >
    <template #header-actions>
      <div class="power-view__actions">
        <div class="power-view__seg" :aria-label="t('labels.power.title')">
          <button
            v-for="flightMode in ['SCM', 'NAV'] as FlightMode[]"
            :key="flightMode"
            type="button"
            class="power-view__seg-btn"
            :class="{ 'power-view__seg-btn--active': mode === flightMode }"
            :aria-pressed="mode === flightMode"
            @click="mode = flightMode"
          >
            {{ t(`labels.power.${flightMode.toLowerCase()}`) }}
          </button>
        </div>
        <Btn :disabled="!Object.keys(overrides).length" @click="overrides = {}">
          {{ t("labels.power.reset") }}
        </Btn>
      </div>
    </template>

    <div
      class="power-view"
      :style="backdrop ? { '--power-backdrop': `url(${backdrop})` } : {}"
    >
      <div class="power-view__head">
        <div class="power-view__sigs">
          <div class="power-view__sig" :title="t('labels.power.ir')">
            <i class="fa-duotone fa-heat" aria-hidden="true" />
            <span>{{ compact(sim.emittedIr) }}</span>
          </div>
          <div class="power-view__sig" :title="t('labels.power.em')">
            <i class="fa-duotone fa-bolt" aria-hidden="true" />
            <span>{{ compact(sim.emittedEm) }}</span>
          </div>
          <button
            v-if="crossSection"
            type="button"
            class="power-view__sig power-view__sig--toggle"
            :title="t('labels.power.csAxisHint')"
            @click="cycleAxis"
          >
            <i class="fa-duotone fa-diamond" aria-hidden="true" />
            <span>
              {{ compact(axisValue(axis)) }}
              <small>{{ axis.toUpperCase() }}</small>
            </span>
          </button>
        </div>

        <div class="power-view__readouts">
          <div
            v-if="sim.coolingMaxPerSec > 0"
            class="power-view__readout"
            :class="{ 'power-view__readout--over': coolingPercent > 100 }"
          >
            <span class="power-view__readout-label">
              {{ t("labels.power.cooling") }}
            </span>
            <div class="power-view__track" aria-hidden="true">
              <div :style="{ width: `${Math.min(coolingPercent, 100)}%` }" />
            </div>
            <span class="power-view__readout-value">{{ coolingPercent }}%</span>
          </div>
          <div v-if="sim.aimAssistMax > 0" class="power-view__readout">
            <span class="power-view__readout-label">
              {{ t("labels.power.aimAssist") }}
            </span>
            <div class="power-view__track" aria-hidden="true">
              <div
                :style="{
                  width: `${(sim.aimAssist / sim.aimAssistMax) * 100}%`,
                }"
              />
            </div>
            <span class="power-view__readout-value">
              {{ num(sim.aimAssist) }} m
            </span>
          </div>
        </div>
      </div>

      <div
        v-if="presets && (presetsEditable || presetList.length)"
        class="power-view__presets"
        :class="{ 'power-view__presets--editing': editing }"
        data-test="power-presets"
      >
        <ChipRow ref="row" :label="t('labels.power.planner.presets.title')">
          <Chip
            v-for="preset in presetList"
            :key="preset.name"
            :data-preset-name="preset.name"
            :state="isApplied(preset) ? 'included' : 'neutral'"
            :editable="presetsEditable && editing"
            :edit-label="
              t('labels.power.planner.presets.rename', { name: preset.name })
            "
            :sortable="presetsEditable && editing"
            :sort-label="t('actions.reorder')"
            data-test="power-preset-apply"
            @toggle="applyPreset(preset)"
            @edit="startRename(preset)"
            @move="movePreset(preset, $event)"
          >
            {{ preset.name }}
          </Chip>

          <template v-if="presetsEditable" #actions>
            <form
              v-if="adding && !mobile"
              class="power-view__preset-form"
              data-test="power-preset-save"
              @submit.prevent="saveCurrent"
            >
              <FormInput
                v-model="newName"
                name="powerPresetName"
                class="power-view__preset-input"
                no-label
                :placeholder="t('labels.power.planner.presets.name')"
                autofocus
              />
              <Btn
                v-tooltip="t('labels.power.planner.presets.save')"
                type="submit"
                :size="BtnSizesEnum.XS"
                :disabled="!canSave"
                :loading="presetsSaving"
                :aria-label="t('labels.power.planner.presets.save')"
                data-test="power-preset-confirm"
              >
                <i class="fa-regular fa-check" />
              </Btn>
              <Btn
                v-tooltip="t('actions.cancel')"
                :size="BtnSizesEnum.XS"
                :aria-label="t('actions.cancel')"
                @click="adding = false"
              >
                <i class="fa-regular fa-xmark" />
              </Btn>
            </form>

            <form
              v-if="renaming && !mobile"
              class="power-view__preset-form"
              @submit.prevent="saveRename"
            >
              <FormInput
                v-model="renameTo"
                name="powerPresetRename"
                class="power-view__preset-input"
                no-label
                :placeholder="t('labels.power.planner.presets.name')"
                autofocus
              />
              <Btn
                v-tooltip="t('actions.save')"
                type="submit"
                :size="BtnSizesEnum.XS"
                :disabled="!renameValid || presetsSaving"
                :aria-label="t('actions.save')"
              >
                <i class="fa-regular fa-check" />
              </Btn>
              <Btn
                v-tooltip="
                  t('labels.power.planner.presets.delete', { name: renaming })
                "
                :size="BtnSizesEnum.XS"
                tone="danger"
                :disabled="presetsSaving"
                :aria-label="
                  t('labels.power.planner.presets.delete', { name: renaming })
                "
                data-test="power-preset-delete"
                @click="deletePreset"
              >
                <i class="fa-regular fa-trash" />
              </Btn>
              <Btn
                v-tooltip="t('actions.cancel')"
                :size="BtnSizesEnum.XS"
                :aria-label="t('actions.cancel')"
                @click="renaming = null"
              >
                <i class="fa-regular fa-xmark" />
              </Btn>
            </form>

            <Btn
              v-if="canAdd && !adding"
              v-tooltip="t('labels.power.planner.presets.add')"
              :size="BtnSizesEnum.XS"
              :aria-label="t('labels.power.planner.presets.add')"
              data-test="power-preset-add"
              @click="startAdding"
            >
              <i class="fa-regular fa-plus" />
            </Btn>
            <Btn
              v-if="presetList.length"
              v-tooltip="editing ? t('actions.done') : t('actions.edit')"
              :size="BtnSizesEnum.XS"
              :active="editing"
              :aria-label="editing ? t('actions.done') : t('actions.edit')"
              :aria-pressed="editing"
              class="power-view__presets-edit"
              data-test="power-presets-edit"
              @click="toggleEditing"
            >
              <i
                :class="editing ? 'fa-regular fa-check' : 'fa-regular fa-pen'"
              />
            </Btn>
          </template>

          <template #menu>
            <div class="power-view__presets-menu">
              <template v-if="presetsEditable && editing">
                <div
                  v-for="(preset, index) in presetList"
                  :key="`menu-edit-${preset.name}`"
                  class="power-view__presets-menu-row"
                >
                  <Chip bare class="power-view__presets-menu-name">
                    {{ preset.name }}
                  </Chip>
                  <BtnGroup :size="BtnSizesEnum.SM">
                    <Btn
                      :aria-label="t('actions.moveUp')"
                      :disabled="index === 0"
                      @click.stop="movePreset(preset, -1)"
                    >
                      <i class="fa-regular fa-arrow-up" />
                    </Btn>
                    <Btn
                      :aria-label="t('actions.moveDown')"
                      :disabled="index === presetList.length - 1"
                      @click.stop="movePreset(preset, 1)"
                    >
                      <i class="fa-regular fa-arrow-down" />
                    </Btn>
                    <Btn
                      :aria-label="
                        t('labels.power.planner.presets.rename', {
                          name: preset.name,
                        })
                      "
                      @click="startRename(preset)"
                    >
                      <i class="fa-regular fa-pen" />
                    </Btn>
                  </BtnGroup>
                </div>
              </template>
              <template v-else>
                <Btn
                  v-for="preset in presetList"
                  :key="`menu-${preset.name}`"
                  :active="isApplied(preset)"
                  @click="applyPreset(preset)"
                >
                  {{ preset.name }}
                </Btn>
              </template>
              <template v-if="presetsEditable">
                <hr v-if="presetList.length" />
                <Btn v-if="canAdd" @click="startAdding">
                  <i class="fa-regular fa-plus" />
                  {{ t("labels.power.planner.presets.add") }}
                </Btn>
                <Btn v-if="presetList.length" @click.stop="toggleEditing">
                  <i
                    :class="
                      editing ? 'fa-regular fa-check' : 'fa-regular fa-pen'
                    "
                  />
                  {{ editing ? t("actions.done") : t("actions.edit") }}
                </Btn>
              </template>
            </div>
          </template>
        </ChipRow>

        <form
          v-if="adding && mobile"
          class="power-view__preset-form"
          data-test="power-preset-save-menu"
          @submit.prevent="saveCurrent"
        >
          <FormInput
            v-model="newName"
            name="powerPresetName"
            class="power-view__preset-input"
            no-label
            :placeholder="t('labels.power.planner.presets.name')"
            autofocus
          />
          <Btn
            v-tooltip="t('labels.power.planner.presets.save')"
            type="submit"
            :size="BtnSizesEnum.XS"
            :disabled="!canSave"
            :loading="presetsSaving"
            :aria-label="t('labels.power.planner.presets.save')"
            data-test="power-preset-confirm"
          >
            <i class="fa-regular fa-check" />
          </Btn>
          <Btn
            v-tooltip="t('actions.cancel')"
            :size="BtnSizesEnum.XS"
            :aria-label="t('actions.cancel')"
            @click="adding = false"
          >
            <i class="fa-regular fa-xmark" />
          </Btn>
        </form>

        <form
          v-if="renaming && mobile"
          class="power-view__preset-form"
          @submit.prevent="saveRename"
        >
          <FormInput
            v-model="renameTo"
            name="powerPresetRename"
            class="power-view__preset-input"
            no-label
            :placeholder="t('labels.power.planner.presets.name')"
            autofocus
          />
          <Btn
            v-tooltip="t('actions.save')"
            type="submit"
            :size="BtnSizesEnum.XS"
            :disabled="!renameValid || presetsSaving"
            :aria-label="t('actions.save')"
          >
            <i class="fa-regular fa-check" />
          </Btn>
          <Btn
            v-tooltip="
              t('labels.power.planner.presets.delete', { name: renaming })
            "
            :size="BtnSizesEnum.XS"
            tone="danger"
            :disabled="presetsSaving"
            :aria-label="
              t('labels.power.planner.presets.delete', { name: renaming })
            "
            data-test="power-preset-delete-menu"
            @click="deletePreset"
          >
            <i class="fa-regular fa-trash" />
          </Btn>
          <Btn
            v-tooltip="t('actions.cancel')"
            :size="BtnSizesEnum.XS"
            :aria-label="t('actions.cancel')"
            @click="renaming = null"
          >
            <i class="fa-regular fa-xmark" />
          </Btn>
        </form>
      </div>

      <div
        class="power-view__columns"
        :style="{
          '--power-columns': rows.length,
          '--power-tallest': tallest,
        }"
      >
        <div
          v-for="row in rows"
          :key="row.family"
          class="power-view__column"
          :class="{
            'power-view__column--off': row.allocated === 0,
            'power-view__column--weapon': row.family === 'weapon',
          }"
        >
          <div class="power-view__bar">
            <div class="power-view__count">
              {{ row.allocated }} / {{ row.capacity }}
            </div>
            <div
              class="power-view__stack"
              role="group"
              :aria-label="t(`labels.power.families.${row.family}`)"
            >
              <template
                v-for="(column, columnIndex) in row.columns"
                :key="column.portPath"
              >
                <template
                  v-for="(member, memberIndex) in column.members"
                  :key="member.portPath"
                >
                  <span
                    v-if="columnIndex > 0 || memberIndex > 0"
                    class="power-view__divider"
                    aria-hidden="true"
                  />
                  <div class="power-view__member">
                    <button
                      v-for="cell in pipCells(member)"
                      :key="`${member.portPath}-${cell.level}`"
                      type="button"
                      class="power-view__pip"
                      :class="{
                        'power-view__pip--on': cell.level <= member.allocated,
                        'power-view__pip--top': cell.level === member.allocated,
                        'power-view__pip--block': cell.span > 1,
                        'power-view__pip--headroom':
                          cell.level > member.fillable,
                      }"
                      :style="{ '--pip-span': cell.span }"
                      :title="member.label"
                      :aria-label="
                        t('labels.power.planner.setPips', {
                          name:
                            member.label ??
                            t(`labels.power.families.${row.family}`),
                          count: cell.level,
                        })
                      "
                      :disabled="cell.level > member.fillable"
                      @click="pick(column, member, cell.level)"
                    >
                      <template v-if="cell.span > 1">{{ cell.span }}</template>
                    </button>
                  </div>
                </template>
              </template>
            </div>
          </div>
          <div class="power-view__family">
            <HardpointCategoryIcon
              v-if="FAMILY_CATEGORY[row.family]"
              :category="FAMILY_CATEGORY[row.family]!"
              class="power-view__icon"
            />
            <span>{{ t(`labels.power.families.${row.family}`) }}</span>
          </div>
          <div class="power-view__parts">{{ row.parts }}</div>
          <div class="power-view__effect" aria-live="polite">
            {{ rowEffect(row)[0] }}
            <small v-if="rowEffect(row)[1]">{{ rowEffect(row)[1] }}</small>
          </div>
        </div>
      </div>

      <div class="power-view__feed" aria-hidden="true">
        <div
          class="power-view__wires"
          :style="{ '--power-columns': rows.length }"
        >
          <span
            v-for="row in rows"
            :key="row.family"
            class="power-view__wire"
            :class="{ 'power-view__wire--off': row.allocated === 0 }"
          />
        </div>
        <span class="power-view__trunk" />
      </div>

      <div class="power-view__plant-card">
        <div class="power-view__plant-label">
          {{ t("labels.hardpoint.categories.powerplant") }}
        </div>
        <div class="power-view__plant-list">
          <div
            v-for="plant in plants"
            :key="plant.key"
            class="power-view__plant"
          >
            <strong>{{ plant.name }}</strong>
            <span v-if="plant.count > 1"> ×{{ plant.count }}</span>
            <span class="power-view__muted">
              {{
                t("labels.power.planner.plantSegments", {
                  segments: num(plantSegments(plant.hardpoint)),
                })
              }}
            </span>
          </div>
        </div>
        <div class="power-view__plant-total">
          {{ used }} / {{ sim.totalSegments }}
          <span>{{ t("labels.power.planner.segmentsTotal") }}</span>
        </div>
      </div>

      <section v-if="energyGuns.length" class="power-view__energy">
        <h3 class="power-view__section-label">
          {{ t("labels.power.planner.weaponEnergy") }}
        </h3>
        <div class="power-view__guns">
          <article
            v-for="gun in energyGuns"
            :key="gun.key"
            class="power-view__gun"
          >
            <header class="power-view__gun-head">
              <div>
                <div class="power-view__gun-name">
                  {{ gun.name }}
                  <span v-if="gun.count > 1">×{{ gun.count }}</span>
                </div>
                <div class="power-view__muted">
                  {{
                    gun.energy
                      ? t("labels.power.planner.energyGun")
                      : t("labels.power.planner.heatGun")
                  }}
                </div>
              </div>
              <div class="power-view__effect">
                {{ num(gun.sustainedDps) }} DPS
                <small>
                  {{ t("labels.power.planner.sustainedEach") }}
                </small>
              </div>
            </header>
            <div class="power-view__gun-bars">
              <div
                v-if="gun.energy"
                class="power-view__readout power-view__readout--gun"
              >
                <span class="power-view__readout-label">
                  {{ t("labels.power.planner.capacitor") }}
                </span>
                <div class="power-view__track" aria-hidden="true">
                  <div
                    :style="{
                      width: `${(gun.capacity / (gun.capacityMax || 1)) * 100}%`,
                    }"
                  />
                </div>
                <span class="power-view__readout-value">
                  {{
                    t("labels.power.planner.shots", {
                      count: gun.capacity,
                      max: num(gun.capacityMax),
                    })
                  }}
                </span>
              </div>
              <div class="power-view__readout power-view__readout--gun">
                <span class="power-view__readout-label">
                  {{ t("labels.power.planner.firing") }}
                </span>
                <div class="power-view__track" aria-hidden="true">
                  <div :style="{ width: `${gun.share * 100}%` }" />
                </div>
                <span class="power-view__readout-value">
                  {{ percent(gun.share) }}
                </span>
              </div>
            </div>
            <dl class="power-view__gun-figures">
              <div>
                <dt>
                  {{
                    gun.energy
                      ? t("labels.power.planner.emptiesIn")
                      : t("labels.power.planner.overheatsIn")
                  }}
                </dt>
                <dd>{{ seconds(gun.emptyIn) }}</dd>
              </div>
              <div>
                <dt>
                  {{
                    gun.energy
                      ? t("labels.power.planner.refillsIn")
                      : t("labels.power.planner.recoversIn")
                  }}
                </dt>
                <dd>{{ seconds(gun.refillIn) }}</dd>
              </div>
              <div v-if="gun.energy">
                <dt>{{ t("labels.power.planner.regenLabel") }}</dt>
                <dd>
                  {{
                    t("labels.power.planner.shotsPerSecond", {
                      rate: num(gun.regen),
                    })
                  }}
                </dd>
              </div>
            </dl>
          </article>
        </div>
      </section>

      <ul class="power-view__legend">
        <li>
          <span class="power-view__sample" aria-hidden="true">
            <span class="power-view__sample-pip power-view__sample-pip--block">
              2
            </span>
          </span>
          {{ t("labels.power.planner.legendBlock") }}
        </li>
        <li>
          <span class="power-view__sample" aria-hidden="true">
            <span class="power-view__sample-pip power-view__sample-pip--on" />
          </span>
          {{ t("labels.power.planner.legendOn") }}
        </li>
        <li>
          <span class="power-view__sample" aria-hidden="true">
            <span class="power-view__sample-pip" />
          </span>
          {{ t("labels.power.planner.legendFree") }}
        </li>
        <li>
          <span class="power-view__sample" aria-hidden="true">
            <span
              class="power-view__sample-pip power-view__sample-pip--headroom"
            />
          </span>
          {{ t("labels.power.planner.legendHeadroom") }}
        </li>
        <li>
          <span class="power-view__sample" aria-hidden="true">
            <span class="power-view__sample-pip power-view__sample-pip--on" />
            <span class="power-view__divider" />
            <span class="power-view__sample-pip power-view__sample-pip--on" />
          </span>
          {{ t("labels.power.planner.legendShared") }}
        </li>
      </ul>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
