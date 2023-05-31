<template>
  <div>
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
          v-for="group in ['avionic', 'system']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['propulsion', 'thruster']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['weapon']"
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
    <Loader :loading="loading" :fixed="true" />
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import modelHardpointsCollection from "@/frontend/api/collections/ModelHardpoints";
import type { ModelHardpointsCollection } from "@/frontend/api/collections/ModelHardpoints";
import HardpointGroup from "./Group/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

type Props = {
  model: TModel;
};

const props = defineProps<Props>();

const collection: ModelHardpointsCollection = modelHardpointsCollection;

const loading = ref(false);

const hardpoints = computed(() => {
  return collection.records || [];
});

const erkulUrl = computed<string | null>(() => {
  if (
    !props.model ||
    props.model.productionStatus !== "flight-ready" ||
    !props.model.erkulIdentifier
  ) {
    return null;
  }

  return `https://www.erkul.games/ship/${props.model.erkulIdentifier}`;
});

const scunpackedUrl = computed<string | null>(() => {
  if (!props.model.scIdentifier) {
    return null;
  }

  return `https://scunpacked.com/ships/${props.model.scIdentifier}`;
});

const hardpointsForGroup = (group: string) => {
  return hardpoints.value.filter((hardpoint) => hardpoint.group === group);
};

watch(
  () => props.model,
  () => {
    fetch();
  }
);

onMounted(() => {
  fetch();
});

const fetch = async () => {
  if (!props.model) {
    return;
  }

  loading.value = true;

  await collection.findAllByModel(props.model.slug);

  loading.value = false;
};
</script>

<script lang="ts">
export default {
  name: "ModelHardpoints",
};
</script>
