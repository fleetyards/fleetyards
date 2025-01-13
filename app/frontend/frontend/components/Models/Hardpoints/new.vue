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
import { useQuery } from "@tanstack/vue-query";
import { useApiClient } from "@/frontend/composables/useApiClient";
import {
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
  if (!props.model || !props.model.erkulIdentifier) {
    return null;
  }

  return `https://www.erkul.games/ship/${props.model.erkulIdentifier}`;
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
    ? HardpointSourceEnum.GAME_FILES
    : HardpointSourceEnum.SHIP_MATRIX,
);

const { models: modelsService } = useApiClient();

const {
  isLoading,
  isFetching,
  data: hardpoints,
  refetch,
} = useQuery({
  queryKey: ["model-hardpoints", props.model.slug, source],
  queryFn: () => {
    return modelsService.modelHardpoints({
      slug: props.model.slug,
      source: source.value,
    });
  },
  enabled: !!props.model,
});
</script>

<template>
  <div id="hardpoints" class="row hardpoints">
    <div class="col-12">
      <div v-if="erkulUrl" class="d-flex justify-content-center">
        <Btn :href="erkulUrl" mobile-block class="erkul-link">
          <small>{{ t("labels.erkul.prefix") }}</small>
          <i />
          {{ t("labels.erkul.link") }}
        </Btn>
      </div>
      <div class="d-flex justify-content-end">
        <BtnGroup>
          <Btn
            :active="source === HardpointSourceEnum.GAME_FILES"
            :disabled="!model.scIdentifier"
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
      <div v-if="hardpoints?.length" class="row">
        <div class="col-12 col-md-6 col-lg-4">
          <HardpointGroup
            v-for="group in [
              HardpointGroupEnum.AVIONIC,
              HardpointGroupEnum.SYSTEM,
              HardpointGroupEnum.OTHER,
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
          <HardpointGroup
            v-for="group in [HardpointGroupEnum.SEAT]"
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
