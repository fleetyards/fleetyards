<template>
  <div class="fleetchart-slider">
    <VueSlider
      ref="scaleSlider"
      v-model="innerValue"
      :min="minScale"
      :max="maxScale"
      :interval="interval"
      :marks="marks"
      :dot-size="20"
      :tooltip-formatter="label"
      :process="false"
      :lazy="true"
      @change="update"
    />
  </div>
</template>

<script lang="ts" setup>
import VueSlider from "vue-slider-component";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  modelValue?: number;
  maxScale?: number;
  minScale?: number;
  interval?: number;
  mark?: number;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: 1,
  maxScale: 20,
  minScale: 0.2,
  interval: 0.5,
  mark: 2,
});

const innerValue = ref(1);

const mobile = useMobile();

const innerMark = computed(() => {
  return mobile.value ? 5 : props.mark;
});

watch(
  () => props.modelValue,
  () => {
    innerValue.value = props.modelValue;
  },
);

onMounted(() => {
  innerValue.value = props.modelValue;
});

const emit = defineEmits(["update:modelValue"]);

const update = (value: number) => {
  emit("update:modelValue", value);
};

const marks = (value: number) => {
  if (value % innerMark.value === 0) {
    return {
      label: label(value),
    };
  }

  return false;
};

const label = (value: number) => {
  return `${value}x`;
};
</script>

<script lang="ts">
export default {
  name: "FleetchartSlider",
};
</script>
