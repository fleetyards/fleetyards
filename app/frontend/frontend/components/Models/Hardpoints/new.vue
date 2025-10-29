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
import { useI18n } from "@/shared/composables/useI18n";
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
  () => {
    refetch();
  },
);

const source = ref(
  props.model.scIdentifier
    ? HardpointSourceEnum.game_files
    : HardpointSourceEnum.ship_matrix,
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
</script>

<template>
  <div id="hardpoints" class="row hardpoints">
    <div class="col-12">
      <div v-if="model.scIdentifier" class="d-flex justify-content-center">
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
      <div class="d-flex justify-content-end">
        <BtnGroup>
          <Btn
            :active="source === HardpointSourceEnum.game_files"
            :disabled="!model.scIdentifier"
            @click="source = HardpointSourceEnum.game_files"
          >
            {{
              t(`labels.hardpoint.sources.${HardpointSourceEnum.game_files}`)
            }}
          </Btn>
          <Btn
            :active="source === HardpointSourceEnum.ship_matrix"
            @click="source = HardpointSourceEnum.ship_matrix"
          >
            {{
              t(`labels.hardpoint.sources.${HardpointSourceEnum.ship_matrix}`)
            }}
          </Btn>
        </BtnGroup>
      </div>
      <div v-if="hardpoints?.length" class="row">
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [
              HardpointGroupEnum.avionic,
              HardpointGroupEnum.system,
              HardpointGroupEnum.other,
            ]"
            :key="group"
            :group="group"
            :hardpoints="hardpointsForGroup(group)"
          />
        </div>
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [
              HardpointGroupEnum.propulsion,
              HardpointGroupEnum.thruster,
            ]"
            :key="group"
            :group="group"
            :hardpoints="hardpointsForGroup(group)"
          />
        </div>
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [
              HardpointGroupEnum.weapon,
              HardpointGroupEnum.auxiliary,
            ]"
            :key="group"
            :group="group"
            :hardpoints="hardpointsForGroup(group)"
          />
          <HardpointGroup
            v-for="group in [HardpointGroupEnum.seat]"
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
