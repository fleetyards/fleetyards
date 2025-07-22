<template>
  <VueSlider
    v-model="scale"
    :min="10"
    :max="max"
    :interval="10"
    :dot-size="20"
    :marks="mark"
    :tooltip-formatter="label"
    :process="false"
    lazy
    @change="updateScale"
  />
</template>

<script lang="ts" setup>
import VueSlider from "vue-slider-component";

type Props = {
  initialScale: number;
};

const props = defineProps<Props>();

const scale = ref<number>(props.initialScale);

const max = computed(() => 300);

const mark = (value: number) => {
  if (value % 50 === 0 || value === 10) {
    return {
      label: label(value),
    };
  }
  return false;
};

const emit = defineEmits(["change"]);

const updateScale = (value: number) => {
  emit("change", value);
};

const label = (value: number) => `${value} %`;
</script>

<script lang="ts">
export default {
  name: "SliderComponent",
};
</script>
