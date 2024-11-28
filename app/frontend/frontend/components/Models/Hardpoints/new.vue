<script lang="ts">
export default {
  name: "ModelHardpoints",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import HardpointGroup from "./Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
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
  if (!props.model || !props.model.erkulIdentifier) {
    return null;
  }

  return `https://www.erkul.games/ship/${props.model.erkulIdentifier}`;
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

<template>
  <div id="hardpoints" class="row components">
    <div class="col-12">
      <div v-if="erkulUrl" class="d-flex justify-content-center">
        <Btn :href="erkulUrl" mobile-block class="erkul-link">
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
      <Loader :loading="isLoading || isFetching" :fixed="true" />
    </div>
  </div>
</template>
