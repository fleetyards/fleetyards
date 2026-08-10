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
import ModelPowerDistribution from "@/frontend/components/Models/PowerDistribution/index.vue";
import ModelRefuelBoom from "@/frontend/components/Models/RefuelBoom/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useLoadoutStats } from "@/frontend/composables/useLoadoutStats";
import type { PortOverrides } from "@/frontend/composables/useLoadoutSim";
import type { FlightMode } from "@/frontend/composables/powerSim";
import { useShieldStats } from "@/frontend/composables/useShieldStats";
import {
  useModelHardpoints as useModelHardpointsQuery,
  HardpointGroupEnum,
  HardpointSourceEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

provide(
  "modelSlug",
  computed(() => props.model.slug),
);

provide(
  "quantumFuelTankSize",
  computed(() => props.model.metrics?.quantumFuelTankSize),
);

const density = ref<"compact" | "expanded">("compact");
provide("hardpointDensity", density);

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

const hardpointsForGroup = (group: HardpointGroupEnum): Hardpoint[] => {
  return (hardpoints.value?.filter((hardpoint) => hardpoint.group === group) ||
    []) as Hardpoint[];
};

watch(
  () => props.model,
  async () => {
    await refetch();
  },
);

const source = ref(
  props.model.inGame
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
  query: { enabled: !!props.model },
});

// User pip choices from the Power Distribution control; empty = auto (default).
const powerOverrides = ref<PortOverrides>({});
const flightMode = ref<FlightMode>("SCM");

// Reset overrides when the ship (or hardpoint source) changes.
watch([() => props.model.slug, source], () => {
  powerOverrides.value = {};
});

const combatStats = useLoadoutStats(
  () => (hardpoints.value as Hardpoint[] | undefined) ?? [],
  () => props.model.metrics?.weaponPoolSize,
  powerOverrides,
);

provide(
  "weaponPoolSize",
  computed(() => props.model.metrics?.weaponPoolSize),
);

// The user's pip choices, so the Combat card totals recompute from the same
// distribution the control shows.
provide("powerOverrides", powerOverrides);

// The loadout-wide weapon-power throttle, so per-weapon rows show the same
// sustained factor the Combat card totals from.
provide(
  "weaponPowerRatio",
  computed(() => combatStats.value.weaponPowerRatio),
);

const shieldStats = useShieldStats(
  () => (hardpoints.value as Hardpoint[] | undefined) ?? [],
);
</script>

<template>
  <div id="hardpoints" class="row hardpoints">
    <div class="col-12">
      <div v-if="model.inGame" class="flex justify-center">
        <BtnGroup>
          <span class="text-muted">{{ t("labels.hardpoints.prefix") }}</span>
          <Btn :href="erkulUrl" mobile-block class="erkul-link">
            <i />
            {{ t("labels.hardpoints.erkul") }}
          </Btn>
          <Btn
            v-tooltip="t('labels.hardpoints.spviewerTitle')"
            :href="spviewerUrl"
            mobile-block
            class="spviewer-link"
          >
            <i />
            {{ t("labels.hardpoints.spviewer") }}
          </Btn>
        </BtnGroup>
      </div>
      <div class="flex justify-end hardpoints__toolbar">
        <BtnGroup>
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
      <ModelRefuelBoom :model="model" />
      <div
        v-if="
          source === HardpointSourceEnum.GAME_FILES &&
          (combatStats.hasData ||
            shieldStats.hasData ||
            model.metrics.hullHealth)
        "
        class="metrics-grid"
      >
        <div class="metrics-grid__col">
          <ModelCombatMetrics :hardpoints="hardpoints as Hardpoint[]" />
          <ModelPowerDistribution
            v-model="powerOverrides"
            v-model:mode="flightMode"
            :hardpoints="hardpoints as Hardpoint[]"
            :weapon-pool-size="model.metrics?.weaponPoolSize"
          />
        </div>
        <div class="metrics-grid__col">
          <ModelDefenseMetrics
            :hardpoints="hardpoints as Hardpoint[]"
            :model-name="model.name"
          />
          <ModelHullMetrics
            :hull-health="model.metrics.hullHealth"
            :hull-parts="model.metrics.hullParts"
            :hull-doors="model.metrics.hullDoors"
          />
        </div>
      </div>
      <div v-if="hardpoints?.length" class="hardpoints__viewbar">
        <span class="hardpoints__viewbar-label">
          {{ t("labels.hardpoint.density.title") }}
        </span>
        <div
          class="hardpoints__seg"
          role="tablist"
          :aria-label="t('labels.hardpoint.density.title')"
        >
          <button
            type="button"
            class="hardpoints__seg-btn"
            :class="{
              'hardpoints__seg-btn--active': density === 'compact',
            }"
            :aria-pressed="density === 'compact'"
            @click="density = 'compact'"
          >
            {{ t("labels.hardpoint.density.compact") }}
          </button>
          <button
            type="button"
            class="hardpoints__seg-btn"
            :class="{
              'hardpoints__seg-btn--active': density === 'expanded',
            }"
            :aria-pressed="density === 'expanded'"
            @click="density = 'expanded'"
          >
            {{ t("labels.hardpoint.density.expanded") }}
          </button>
        </div>
      </div>
      <div v-if="hardpoints?.length" class="row">
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [
              HardpointGroupEnum.AVIONIC,
              HardpointGroupEnum.SYSTEM,
              HardpointGroupEnum.OTHER,
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
      <Loader :loading="isLoading || isFetching" fixed />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
