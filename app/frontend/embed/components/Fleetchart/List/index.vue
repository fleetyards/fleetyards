<template>
  <div>
    <div v-if="slider" class="row justify-content-lg-center">
      <div class="col-12 col-lg-4">
        <FleetchartSlider
          :initial-scale="fleetchartScale"
          @change="updateFleetchartScale"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 fleetchart-wrapper">
        <transition-group
          id="fleetchart"
          name="fade-list"
          class="row fleetchart"
          tag="div"
          :appear="true"
        >
          <FleetchartItem
            v-for="(model, index) in internalModels"
            :key="`fleetchart-item-${index}-${model.slug}`"
            :model="model"
            :scale="fleetchartScale"
          />
        </transition-group>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import FleetchartSlider from "@/embed/components/Fleetchart/Slider/index.vue";
import FleetchartItem from "@/embed/components/Fleetchart/Item/index.vue";
import type { ModelMinimal } from "@/services/fyApi";
import { useEmbedStore } from "@/embed/stores/embed";
import { storeToRefs } from "pinia";

const embedStore = useEmbedStore();

type Props = {
  models: ModelMinimal[];
  slider?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  slider: true,
});

const { fleetchartScale } = storeToRefs(embedStore);

const internalModels = ref<ModelMinimal[]>([]);

watch(
  () => props.models,
  () => {
    internalModels.value = [...props.models];
    internalModels.value.sort(sortByFleetchartLength);
  }
);

const getLength = (model: ModelMinimal) => {
  if (model.metrics.fleetchartLength) {
    return model.metrics.fleetchartLength;
  }

  return model.metrics.length || 0;
};

const sortByFleetchartLength = (a: ModelMinimal, b: ModelMinimal) => {
  if (getLength(a) > getLength(b)) {
    return -1;
  }

  if (getLength(a) < getLength(b)) {
    return 1;
  }

  return 0;
};
const updateFleetchartScale = (value: number) => {
  embedStore.fleetchartScale = value;
};

onMounted(() => {
  internalModels.value = [...props.models];
  internalModels.value.sort(sortByFleetchartLength);
});
</script>

<script lang="ts">
export default {
  name: "FleetchartList",
};
</script>
