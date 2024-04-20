<template>
  <transition-group name="fade-list" class="row" tag="div" :appear="true">
    <div
      v-for="(model, index) in internalModels"
      :key="`panel-${index}-${model.slug}`"
      class="col-12 col-md-6 col-xl-4 col-xxl-4 fade-list-item"
    >
      <ModelPanel :model="model" :details="details" :count="count(model)" />
    </div>
  </transition-group>
</template>

<script lang="ts" setup>
import ModelPanel from "@/embed/components/Models/Panel/index.vue";
import type { EnhancedModelMinimal } from "@/embed/pages/Home.vue";
import { type Model } from "@/services/fyApi";
import { useEmbedStore } from "@/embed/stores/embed";
import { storeToRefs } from "pinia";

type Props = {
  models: (EnhancedModelMinimal | Model)[];
};

const props = defineProps<Props>();

const internalModels = ref<(EnhancedModelMinimal | Model)[]>([]);

const embedStore = useEmbedStore();

const { details, grouping } = storeToRefs(embedStore);

watch(
  () => props.models,
  () => {
    internalModels.value = props.models;
  },
);

onMounted(() => {
  internalModels.value = props.models;
});

const count = (model: EnhancedModelMinimal | Model) => {
  if (!grouping.value) {
    return undefined;
  }

  return (model as EnhancedModelMinimal).count;
};
</script>

<script lang="ts">
export default {
  name: "ModelList",
};
</script>
