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
import ModelSurvivabilityMetrics from "@/frontend/components/Models/SurvivabilityMetrics/index.vue";
import ModelRefuelBoom from "@/frontend/components/Models/RefuelBoom/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useLoadoutStats } from "@/frontend/composables/useLoadoutStats";
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

const combatStats = useLoadoutStats(
  () => (hardpoints.value as Hardpoint[] | undefined) ?? [],
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
      <div class="flex justify-end">
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
        v-if="combatStats.hasData || shieldStats.hasData"
        class="row combat-row"
      >
        <div class="col-12 col-lg-6">
          <ModelCombatMetrics :hardpoints="(hardpoints as Hardpoint[])" />
        </div>
        <div class="col-12 col-lg-6">
          <ModelSurvivabilityMetrics :hardpoints="(hardpoints as Hardpoint[])" />
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
@import "new";
</style>
