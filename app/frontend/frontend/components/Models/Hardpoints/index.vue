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
import { HARDPOINT_COLUMNS } from "./columns";
import SummaryFigures from "./Summary/Figures/index.vue";
import {
  hardpointCardFoldKey,
  metricsCardFoldKey,
} from "@/frontend/components/Models/MetricsCard/fold";
import { holdsAny } from "./summaryRows";
import { useModelsStore } from "@/frontend/stores/models";
import { useShieldStats } from "@/frontend/composables/useShieldStats";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
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
import {
  emptySplits,
  type FlightMode,
  type PowerSplits,
} from "@/frontend/composables/powerSim";
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
  // Whose fitting it is, to remember the reader's folded cards against.
  loadoutId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  cargoHolds: () => [],
  fitting: undefined,
  changed: undefined,
  crafted: undefined,
  loadoutId: undefined,
});

const modelsStore = useModelsStore();

// A loadout's cards are remembered for that loadout, not for every one of the ship.
const foldScope = computed(() => props.loadoutId ?? props.model.slug);

provide(metricsCardFoldKey, {
  collapsed: (key) =>
    modelsStore.sectionCollapsed(foldScope.value, `metrics-${key}`),
  toggle: (key) => modelsStore.toggleSection(foldScope.value, `metrics-${key}`),
});

// What differs from stock is what a loadout's page is for, so a card holding such
// a part opens in full, ready to read. Every other card opens on its summary.
const altered = computed(
  () => new Set([...(props.changed ?? []), ...(props.crafted ?? [])]),
);

const opensExpanded = (group: string) =>
  holdsAny(
    (props.fitting ?? []).filter((hardpoint) => hardpoint.group === group),
    altered.value,
  );

const groupCollapsed = (group: string) =>
  opensExpanded(group) ===
  modelsStore.hardpointGroupFlipped(foldScope.value, group);

provide(hardpointCardFoldKey, {
  collapsed: groupCollapsed,
  toggle: (group) => modelsStore.toggleHardpointGroup(foldScope.value, group),
});

const metricsAdvanced = computed(() => modelsStore.shipMetricsAdvanced);

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
  "hardpointCargoHolds",
  computed(() => props.cargoHolds),
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

// The angled view, coloured where there is one, as the loadout editor shows it.
const backdrop = computed(() => {
  const media = props.model.media;
  const file =
    media?.angledViewColored || media?.angledView || media?.storeImage;

  return file ? file.largeUrl || file.url : undefined;
});

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
} = useModelHardpointsQuery(
  computed(() => props.model.slug),
  modelHardpointsQueryParams,
  {
    query: { enabled: () => !!props.model && !props.fitting },
  },
);

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

// User pip choices from the Power Distribution control, one split per flight
// mode; empty = auto (default). Everything on the page reads the split of the
// mode the card is in.
const powerSplits = ref<PowerSplits>(emptySplits());
const flightMode = ref<FlightMode>("SCM");

const powerOverrides = computed<PortOverrides>({
  get: () => powerSplits.value[flightMode.value],
  set: (overrides) => {
    powerSplits.value = { ...powerSplits.value, [flightMode.value]: overrides };
  },
});

// Reset overrides when the ship (or hardpoint source) changes.
watch([() => props.model.slug, source], () => {
  powerSplits.value = emptySplits();
});

const regenModifier = computed(() => props.model.metrics?.weaponRegenModifier);

// Combat figures are what the ship does in a fight, so they read the SCM
// split whatever mode the power card shows.
const combatOverrides = computed(() => powerSplits.value.SCM);

const combatStats = useLoadoutStats(
  loadoutHardpoints,
  () => props.model.metrics?.weaponPoolSize,
  combatOverrides,
  regenModifier,
);

provide(
  "weaponPoolSize",
  computed(() => props.model.metrics?.weaponPoolSize),
);

// The SCM split, so the Combat card totals recompute from the pips set there.
provide("powerOverrides", combatOverrides);

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

// The summary answers for the ship on auto power. Pips set on the advanced cards
// have no control in view there, and a shield on zero would just lose its tile.
const autoPower = emptySplits().SCM;

const summaryCombat = useLoadoutStats(
  loadoutHardpoints,
  () => props.model.metrics?.weaponPoolSize,
  () => autoPower,
  regenModifier,
);

const summaryPower = useLoadoutSim(
  loadoutHardpoints,
  () => props.model.metrics?.weaponPoolSize,
  () => "SCM",
  () => autoPower,
  undefined,
  regenModifier,
);

const summaryShield = useShieldStats(
  loadoutHardpoints,
  () => summaryPower.value.shieldPoolRatio,
);

const fittedByGroup = computed(() => {
  const groups: Partial<Record<HardpointGroupEnum, Hardpoint[]>> = {};

  loadoutHardpoints.value?.forEach((hardpoint) => {
    if (hardpoint.group) {
      (groups[hardpoint.group] ??= []).push(hardpoint);
    }
  });

  return groups;
});

const shownGroups = computed(() =>
  HARDPOINT_COLUMNS.flat().filter(
    (group) => hardpointsForGroup(group).length > 0,
  ),
);

// A column with nothing in it would leave a blank third of the page.
const columns = computed(() =>
  HARDPOINT_COLUMNS.filter((groups) =>
    groups.some((group) => shownGroups.value.includes(group)),
  ),
);

const allCollapsed = computed(() => shownGroups.value.every(groupCollapsed));

// Flips only the cards that do not already open the way that was asked for.
const toggleAllGroups = () => {
  const expanding = allCollapsed.value;

  modelsStore.setFlippedHardpointGroups(
    foldScope.value,
    shownGroups.value.filter((group) => opensExpanded(group) !== expanding),
  );
};

const metricsGrid = ref<HTMLElement>();

useMetricsMasonry(metricsGrid);
</script>

<template>
  <div id="hardpoints" class="row hardpoints">
    <div class="col-12 hardpoints__layout">
      <!-- Planning tools are for the ship as built: a loadout's fitting is one
           plan already. -->
      <div v-if="showMetrics" class="hardpoints__controls">
        <template v-if="metricsAdvanced && !fitting">
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
        <Toggle
          class="hardpoints__advanced"
          inline
          :active="modelsStore.shipMetricsAdvanced"
          :label="t('labels.hardpoints.advancedMode')"
          @toggle="modelsStore.toggleShipMetricsAdvanced()"
        />
      </div>
      <SummaryFigures
        v-if="showMetrics && !metricsAdvanced"
        :model="model"
        :cargo-holds="cargoHolds"
        :dps="summaryCombat.dps.total"
        :missile-damage="summaryCombat.missileDamage"
        :shield-hp="summaryShield.totalHp"
        :loading="loadingHardpoints"
        :pending="isLoading"
      />
      <div
        v-if="showMetrics && metricsAdvanced"
        ref="metricsGrid"
        class="metrics-grid"
      >
        <ModelCombatMetrics
          :hardpoints="loadoutHardpoints"
          :model-name="model.name"
          :loading="loadingHardpoints"
        />
        <ModelPowerDistribution
          v-model="powerOverrides"
          v-model:splits="powerSplits"
          :model-name="model.name"
          :backdrop="backdrop"
          v-model:mode="flightMode"
          :hardpoints="loadoutHardpoints"
          :weapon-pool-size="model.metrics?.weaponPoolSize"
          :regen-modifier="regenModifier"
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
      <div v-if="showMetrics && metricsAdvanced" class="hardpoints__credit">
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
      <div class="hardpoints__toolbar">
        <BtnGroup v-if="!fitting" segmented class="hardpoints__source">
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
        <Btn
          v-if="shownGroups.length && source === HardpointSourceEnum.GAME_FILES"
          class="hardpoints__fold-all"
          :variant="BtnVariantsEnum.BARE"
          data-test="hardpoints-fold-all"
          @click="toggleAllGroups"
        >
          {{
            t(
              allCollapsed
                ? "labels.hardpoints.expandAll"
                : "labels.hardpoints.collapseAll",
            )
          }}
          <i
            class="fa-solid"
            :class="allCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"
            aria-hidden="true"
          />
        </Btn>
      </div>
      <div
        class="hardpoints__list"
        :class="{ 'hardpoints__list--loading': isLoading || isFetching }"
      >
        <!-- First, so it sits at the top of the slot rather than after the
             rows a refetch keeps on screen. -->
        <Loader :loading="isLoading || isFetching" />
        <div
          v-if="shownHardpoints?.length"
          class="hardpoints__columns"
          :style="{ '--hardpoint-columns': columns.length }"
        >
          <div v-for="(groups, column) in columns" :key="column">
            <HardpointGroup
              v-for="group in groups"
              :key="group"
              :group="group"
              :hardpoints="hardpointsForGroup(group)"
              :fitted="fittedByGroup[group] ?? []"
              :summary-only="source === HardpointSourceEnum.SHIP_MATRIX"
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
