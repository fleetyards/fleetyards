<template>
  <div id="hardpoints">
    <div v-if="erkulUrl" class="d-flex justify-content-center">
      <Btn :href="erkulUrl" :mobile-block="true" class="erkul-link">
        <small>{{ t("labels.erkul.prefix") }}</small>
        <i />
        {{ t("labels.erkul.link") }}
      </Btn>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in [
            ModelHardpointGroupEnum.AVIONIC,
            ModelHardpointGroupEnum.SYSTEM,
          ]"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in [
            ModelHardpointGroupEnum.PROPULSION,
            ModelHardpointGroupEnum.THRUSTER,
          ]"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in [ModelHardpointGroupEnum.WEAPON]"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
    </div>
    <div v-if="scunpackedUrl" class="d-flex justify-content-end">
      <Btn
        :href="scunpackedUrl"
        variant="link"
        :mobile-block="true"
        class="scunpacked-link"
      >
        <small>{{ t("labels.scunpacked.prefix") }}</small>
        <i>
          {{ t("labels.scunpacked.link") }}
        </i>
      </Btn>
    </div>
    <Loader :loading="isLoading || isFetching" :fixed="true" />
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import HardpointGroup from "./Group/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useQuery } from "@tanstack/vue-query";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { ModelHardpointGroupEnum } from "@/services/fyApi";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const erkulUrl = computed(() => {
  if (
    !props.model ||
    props.model.productionStatus !== "flight-ready" ||
    !props.model.erkulIdentifier
  ) {
    return null;
  }

  return `https://www.erkul.games/ship/${props.model.erkulIdentifier}`;
});

const scunpackedUrl = computed(() => {
  if (!props.model.scIdentifier) {
    return null;
  }

  return `https://scunpacked.com/ships/${props.model.scIdentifier}`;
});

const hardpointsForGroup = (group: ModelHardpointGroupEnum) => {
  return (
    hardpoints.value?.filter((hardpoint) => hardpoint.group === group) || []
  );
};

watch(
  () => props.model,
  () => {
    refetch();
  },
);

const { models: modelsService } = useApiClient();

const {
  isLoading,
  isFetching,
  data: hardpoints,
  refetch,
} = useQuery({
  queryKey: ["model-hardpoints", props.model.slug],
  queryFn: () => {
    return modelsService.modelHardpoints({
      slug: props.model.slug,
    });
  },
  enabled: !!props.model,
});
</script>

<script lang="ts">
export default {
  name: "ModelHardpoints",
};
</script>
