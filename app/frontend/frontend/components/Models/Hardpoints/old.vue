<script lang="ts">
export default {
  name: "ModelHardpointsOld",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import HardpointGroup from "./old/Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useModelHardpoints as useModelHardpointsQuery,
  ModelHardpointGroupEnum,
  type ModelHardpoint,
  type Model,
} from "@/services/fyApi";

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

const hardpointsForGroup = (group: ModelHardpointGroupEnum) => {
  return (hardpoints.value?.filter((hardpoint) => hardpoint.group === group) ||
    []) as ModelHardpoint[];
};

watch(
  () => props.model,
  () => {
    refetch();
  },
);

const {
  isLoading,
  isFetching,
  data: hardpoints,
  refetch,
} = useModelHardpointsQuery(
  props.model.slug,
  {},
  {
    query: {
      enabled: !!props.model,
    },
  },
);
</script>

<template>
  <div id="hardpoints" class="row components hardpoints-legacy">
    <div class="col-12">
      <div v-if="model.scIdentifier" class="d-flex justify-content-center">
        <BtnGroup>
          <span class="text-muted">{{ t("labels.hardpoints.prefix") }}</span>
          <Btn :href="erkulUrl" :mobile-block="true" class="erkul-link">
            <i />
            {{ t("labels.hardpoints.erkul") }}
          </Btn>
          <Btn
            v-tooltip="t('labels.hardpoints.spviewerTitle')"
            :href="spviewerUrl"
            :mobile-block="true"
            class="spviewer-link"
          >
            <i />
            {{ t("labels.hardpoints.spviewer") }}
          </Btn>
        </BtnGroup>
      </div>
      <div class="row">
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [
              ModelHardpointGroupEnum.avionic,
              ModelHardpointGroupEnum.system,
            ]"
            :key="group"
            :group="group"
            :hardpoints="hardpointsForGroup(group)"
          />
        </div>
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [
              ModelHardpointGroupEnum.propulsion,
              ModelHardpointGroupEnum.thruster,
            ]"
            :key="group"
            :group="group"
            :hardpoints="hardpointsForGroup(group)"
          />
        </div>
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [ModelHardpointGroupEnum.weapon]"
            :key="group"
            :group="group"
            :hardpoints="hardpointsForGroup(group)"
          />
        </div>
      </div>
      <Loader :loading="isLoading || isFetching" :fixed="true" />
    </div>
  </div>
</template>
