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
import Store from "@/embed/lib/Store";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const internalModels = ref<Model[]>([]);

const details = computed(() => Store.getters.details);

const grouping = computed(() => Store.getters.grouping);

watch(
  () => props.models,
  () => {
    internalModels.value = props.models;
  }
);

onMounted(() => {
  internalModels.value = props.models;
});

const count = (model: Model) => {
  if (!grouping.value) {
    return null;
  }

  return model.count;
};
</script>

<script lang="ts">
export default {
  name: "ModelList",
};
</script>
