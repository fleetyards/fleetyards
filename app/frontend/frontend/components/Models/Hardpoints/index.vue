<script lang="ts">
export default {
  name: "ModelHardpoints",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import HardpointGroup from "./Group/index.vue";
import ModelCombatMetrics from "@/frontend/components/Models/CombatMetrics/index.vue";
import ModelDefenseMetrics from "@/frontend/components/Models/DefenseMetrics/index.vue";
import ModelHullMetrics from "@/frontend/components/Models/HullMetrics/index.vue";
import ModelFlightMetrics from "@/frontend/components/Models/FlightMetrics/index.vue";
import ModelCargoMetrics from "@/frontend/components/Models/CargoMetrics/index.vue";
import ModelPowerDistribution from "@/frontend/components/Models/PowerDistribution/index.vue";
import ModelRefuelBoom from "@/frontend/components/Models/RefuelBoom/index.vue";
import ModelExternalFuelTanks from "@/frontend/components/Models/ExternalFuelTanks/index.vue";
import ModelStorageContainers from "@/frontend/components/Models/StorageContainers/index.vue";
import ModelWeaponRacks from "@/frontend/components/Models/WeaponRacks/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useLoadoutStats } from "@/frontend/composables/useLoadoutStats";
import {
  useLoadoutSim,
  type PortOverrides,
} from "@/frontend/composables/useLoadoutSim";
import type { FlightMode } from "@/frontend/composables/powerSim";
import { useMetricsMasonry } from "@/frontend/composables/useMetricsMasonry";
import {
  useEquippedHardpoints,
  type EquippedModules,
} from "@/frontend/composables/useEquippedHardpoints";
import {
  useModelHardpoints as useModelHardpointsQuery,
  HardpointCategoryEnum,
  HardpointGroupEnum,
  HardpointSourceEnum,
  type CargoHold,
  type ComponentController,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";

type Props = {
  model: Model;
  cargoHolds?: CargoHold[];
  // A loadout's fitting: the ship's game-files hardpoints with the loadout's
  // modules and parts grafted in. Shown read-only in place of the hull as built.
  fitting?: Hardpoint[];
  // The ids of the fitting's hardpoints that differ from the stock ship.
  changed?: Set<string>;
  // The ids of the fitting's hardpoints holding a crafted part.
  crafted?: Set<string>;
};

const props = withDefaults(defineProps<Props>(), {
  cargoHolds: () => [],
  fitting: undefined,
  changed: undefined,
  crafted: undefined,
});

provide(
  "hardpointsChanged",
  computed(() => props.changed),
);

provide(
  "hardpointsCrafted",
  computed(() => props.crafted),
);

provide(
  "hardpointsReadOnly",
  computed(() => !!props.fitting),
);

provide(
  "modelSlug",
  computed(() => props.model.slug),
);

provide(
  "quantumFuelTankSize",
  computed(() => props.model.metrics?.quantumFuelTankSize),
);

const { t } = useI18n();

const erkulUrl = computed(() => {
  if (!props.model.scIdentifier) {
    return undefined;
  }

  return `https://www.erkul.games/ship/${props.model.erkulIdentifier}`;
});

const spviewerUrl = computed(() => {
  if (!props.model.scIdentifier) {
    return undefined;
  }

  return `https://www.spviewer.eu/performance?ship=${props.model.scIdentifier}`;
});

const shownHardpoints = computed(
  () => props.fitting ?? (hardpoints.value as Hardpoint[] | undefined),
);

const hardpointsForGroup = (group: HardpointGroupEnum): Hardpoint[] => {
  return (
    shownHardpoints.value?.filter((hardpoint) => hardpoint.group === group) ||
    []
  );
};

watch(
  () => props.model,
  async () => {
    if (!props.fitting) await refetch();
  },
);

// A loadout's fitting is grafted onto the game files' hardpoints, whatever the
// model's flag says.
const source = ref(
  props.model.inGame || props.fitting
    ? HardpointSourceEnum.GAME_FILES
    : HardpointSourceEnum.SHIP_MATRIX,
);

const modelHardpointsQueryParams = computed(() => {
  return {
    source: source.value,
  };
});

const {
  isLoading,
  isFetching,
  data: hardpoints,
  refetch,
} = useModelHardpointsQuery(props.model.slug, modelHardpointsQueryParams, {
  query: { enabled: () => !!props.model && !props.fitting },
});

// Cards that read the hardpoints query render right away and spin while it is
// in flight, so they never pop into the layout once the data lands.
const loadingHardpoints = computed(() => isLoading.value || isFetching.value);

// The module the reader picked per slot, chosen in the slot row and provided by
// the ship page. Grafted onto the slot so every metric below answers for the
// loadout on screen rather than the one the game ships.
const equippedModules = inject<Ref<EquippedModules>>(
  "equippedModules",
  ref({}),
);

const equippedHardpoints = useEquippedHardpoints(
  () => hardpoints.value as Hardpoint[] | undefined,
  equippedModules,
);

// A loadout's fitting already carries its modules' contents.
const loadoutHardpoints = computed(
  () => props.fitting ?? equippedHardpoints.value,
);

// Only a flight controller carries speeds, which tells it apart from the
// shield and missile controllers sharing its category.
const findFlightController = (
  list?: Hardpoint[],
): ComponentController | undefined => {
  for (const hardpoint of list || []) {
    const typeData = hardpoint.component?.typeData as
      ComponentController | undefined;
    if (
      hardpoint.category === HardpointCategoryEnum.CONTROLLER &&
      typeData?.scmSpeed
    ) {
      return typeData;
    }
    const nested = findFlightController(hardpoint.hardpoints);
    if (nested) return nested;
  }
  return undefined;
};

const flightController = computed(() =>
  findFlightController(toValue(loadoutHardpoints)),
);

// User pip choices from the Power Distribution control; empty = auto (default).
const powerOverrides = ref<PortOverrides>({});
const flightMode = ref<FlightMode>("SCM");

// Reset overrides when the ship (or hardpoint source) changes.
watch([() => props.model.slug, source], () => {
  powerOverrides.value = {};
});

const regenModifier = computed(() => props.model.metrics?.weaponRegenModifier);

const combatStats = useLoadoutStats(
  loadoutHardpoints,
  () => props.model.metrics?.weaponPoolSize,
  powerOverrides,
  regenModifier,
);

provide(
  "weaponPoolSize",
  computed(() => props.model.metrics?.weaponPoolSize),
);

// The user's pip choices, so the Combat card totals recompute from the same
// distribution the control shows.
provide("powerOverrides", powerOverrides);

// The ship's engineering buff, which every gun's capacitor and the weapon
// power ratio are scaled by.
provide("weaponRegenModifier", regenModifier);

// Shield power allocation → Defense card scales shield HP/regen with the pips.
const powerSim = useLoadoutSim(
  loadoutHardpoints,
  () => props.model.metrics?.weaponPoolSize,
  flightMode,
  powerOverrides,
  undefined,
  regenModifier,
);
provide(
  "shieldPoolRatio",
  computed(() => powerSim.value.shieldPoolRatio),
);

// Engine power → Flight card scales boosted handling with the thruster pips,
// and zeroes every flight figure when the engine is fully unpowered.
provide(
  "enginePowerRatio",
  computed(() => powerSim.value.enginePowerRatio),
);
provide(
  "enginePowered",
  computed(() => powerSim.value.engineActive),
);

// The loadout-wide weapon-power throttle, so per-weapon rows show the same
// sustained factor the Combat card totals from.
provide(
  "weaponPowerRatio",
  computed(() => combatStats.value.weaponPowerRatio),
);

// Every metrics card is derived from the game-files loadout, which only
// flight-ready ships have — those always carry stats, so no per-card guard. A
// loadout's fitting is read from the game files whatever the model's flag.
const showMetrics = computed(
  () =>
    (props.model.inGame || !!props.fitting) &&
    source.value === HardpointSourceEnum.GAME_FILES,
);

const metricsGrid = ref<HTMLElement>();

useMetricsMasonry(metricsGrid);
</script>

<template>
  <div id="hardpoints" class="row hardpoints">
    <div
      class="col-12 hardpoints__layout"
      :class="{ 'hardpoints__layout--split': showMetrics }"
    >
      <!-- The ship as built: planning tools and the data source. A loadout's
           fitting is one plan, read from the game files. -->
      <div v-if="!fitting" class="hardpoints__controls">
        <template v-if="model.inGame">
          <span class="hardpoints__links-label text-muted">
            {{ t("labels.hardpoints.prefix") }}
          </span>
          <BtnGroup class="hardpoints__links">
            <Btn :href="erkulUrl" class="erkul-link">
              <i />
              {{ t("labels.hardpoints.erkul") }}
            </Btn>
            <Btn
              v-tooltip="t('labels.hardpoints.spviewerTitle')"
              :href="spviewerUrl"
              class="spviewer-link"
            >
              <i />
              {{ t("labels.hardpoints.spviewer") }}
            </Btn>
          </BtnGroup>
        </template>
        <BtnGroup segmented class="hardpoints__source">
          <Btn
            :active="source === HardpointSourceEnum.GAME_FILES"
            :disabled="!model.inGame"
            @click="source = HardpointSourceEnum.GAME_FILES"
          >
            {{
              t(`labels.hardpoint.sources.${HardpointSourceEnum.GAME_FILES}`)
            }}
          </Btn>
          <Btn
            :active="source === HardpointSourceEnum.SHIP_MATRIX"
            @click="source = HardpointSourceEnum.SHIP_MATRIX"
          >
            {{
              t(`labels.hardpoint.sources.${HardpointSourceEnum.SHIP_MATRIX}`)
            }}
          </Btn>
        </BtnGroup>
      </div>
      <div v-if="showMetrics" ref="metricsGrid" class="metrics-grid">
        <ModelCombatMetrics
          :hardpoints="loadoutHardpoints"
          :model-name="model.name"
          :loading="loadingHardpoints"
        />
        <ModelPowerDistribution
          v-model="powerOverrides"
          v-model:mode="flightMode"
          :hardpoints="loadoutHardpoints"
          :weapon-pool-size="model.metrics?.weaponPoolSize"
          :cross-section="model.metrics?.signatureCrossSection"
          :loading="loadingHardpoints"
        />
        <ModelDefenseMetrics
          :hardpoints="loadoutHardpoints"
          :model-name="model.name"
          :loading="loadingHardpoints"
        />
        <ModelHullMetrics
          :hull-health="model.metrics.hullHealth"
          :hull-parts="model.metrics.hullParts"
          :hull-doors="model.metrics.hullDoors"
        />
        <ModelFlightMetrics
          :model="model"
          :boost-capacitor="flightController?.boostCapacitor"
          :hardpoints="loadoutHardpoints"
        />
        <ModelCargoMetrics :model="model" :cargo-holds="cargoHolds" />
        <ModelExternalFuelTanks :model="model" />
        <ModelStorageContainers :model="model" />
        <ModelWeaponRacks :model="model" />
        <ModelRefuelBoom :model="model" />
      </div>
      <div v-if="showMetrics" class="hardpoints__credit">
        <a
          class="hardpoints__credit-link"
          href="https://www.erkul.games/"
          target="_blank"
          rel="noopener"
        >
          <span class="hardpoints__credit-icon" aria-hidden="true" />
          <span>
            {{ t("labels.hardpoints.metricsCredit") }}
            <span class="hardpoints__credit-source">erkul.games</span>
          </span>
          <i
            class="fa-regular fa-arrow-up-right-from-square"
            aria-hidden="true"
          />
        </a>
      </div>
      <div
        class="hardpoints__list"
        :class="{ 'hardpoints__list--loading': isLoading || isFetching }"
      >
        <!-- First, so it sits at the top of the slot rather than after the
             rows a refetch keeps on screen. -->
        <Loader :loading="isLoading || isFetching" />
        <div v-if="shownHardpoints?.length" class="row">
          <div class="col-12 col-md-6 col-lg-4">
            <HardpointGroup
              v-for="group in [
                HardpointGroupEnum.AVIONIC,
                HardpointGroupEnum.SYSTEM,
                HardpointGroupEnum.OTHER,
                HardpointGroupEnum.ORE_POD,
                HardpointGroupEnum.SALVAGE,
                HardpointGroupEnum.MODULE,
                HardpointGroupEnum.EXTERNAL_FUEL_TANK,
              ]"
              :key="group"
              :group="group"
              :hardpoints="hardpointsForGroup(group)"
            />
          </div>
          <div class="col-12 col-md-6 col-lg-4">
            <HardpointGroup
              v-for="group in [
                HardpointGroupEnum.PROPULSION,
                HardpointGroupEnum.THRUSTER,
              ]"
              :key="group"
              :group="group"
              :hardpoints="hardpointsForGroup(group)"
            />
          </div>
          <div class="col-12 col-md-6 col-lg-4">
            <HardpointGroup
              v-for="group in [
                HardpointGroupEnum.WEAPON,
                HardpointGroupEnum.DEFENSE,
                HardpointGroupEnum.AUXILIARY,
              ]"
              :key="group"
              :group="group"
              :hardpoints="hardpointsForGroup(group)"
            />
          </div>
        </div>
        <div v-else-if="!isLoading && !isFetching" class="row">
          <div class="col-12">
            <Empty
              :name="t('resources.hardpoints')"
              :variant="EmptyVariantsEnum.BOX"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
