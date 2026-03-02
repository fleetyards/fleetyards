<script lang="ts">
export default {
  name: "BaseSlider",
};
</script>

<script lang="ts" setup>
type MarkResult = { label: string } | false;

type Props = {
  modelValue?: number;
  min?: number;
  max?: number;
  interval?: number;
  dotSize?: number;
  marks?: (value: number) => MarkResult;
  tooltipFormatter?: (value: number) => string;
  process?: boolean;
  lazy?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: 0,
  min: 0,
  max: 100,
  interval: 1,
  dotSize: 20,
  marks: undefined,
  tooltipFormatter: undefined,
  process: false,
  lazy: false,
});

const emit = defineEmits<{
  "update:modelValue": [value: number];
  change: [value: number];
}>();

const currentValue = ref(props.modelValue);
const isDragging = ref(false);
const railRef = ref<HTMLElement>();

watch(
  () => props.modelValue,
  (newVal) => {
    if (!isDragging.value) {
      currentValue.value = newVal;
    }
  },
);

const valueToPercent = (value: number): number => {
  return ((value - props.min) / (props.max - props.min)) * 100;
};

const positionToValue = (clientX: number): number => {
  const rail = railRef.value;
  if (!rail) return props.min;

  const rect = rail.getBoundingClientRect();
  const percent = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
  const rawValue = props.min + percent * (props.max - props.min);
  const snapped =
    Math.round((rawValue - props.min) / props.interval) * props.interval +
    props.min;

  return Math.max(props.min, Math.min(props.max, +snapped.toFixed(10)));
};

const getClientX = (event: MouseEvent | TouchEvent): number => {
  return "touches" in event ? event.touches[0].clientX : event.clientX;
};

const onDragStart = (event: MouseEvent | TouchEvent) => {
  event.preventDefault();
  isDragging.value = true;

  const newValue = positionToValue(getClientX(event));
  currentValue.value = newValue;

  if (!props.lazy) {
    emit("update:modelValue", newValue);
    emit("change", newValue);
  }

  document.addEventListener("mousemove", onDragMove);
  document.addEventListener("mouseup", onDragEnd);
  document.addEventListener("touchmove", onDragMove);
  document.addEventListener("touchend", onDragEnd);
};

const onDragMove = (event: MouseEvent | TouchEvent) => {
  if (!isDragging.value) return;

  const newValue = positionToValue(getClientX(event));
  currentValue.value = newValue;

  if (!props.lazy) {
    emit("update:modelValue", newValue);
    emit("change", newValue);
  }
};

const onDragEnd = () => {
  if (!isDragging.value) return;
  isDragging.value = false;

  if (props.lazy) {
    emit("update:modelValue", currentValue.value);
  }

  emit("change", currentValue.value);

  document.removeEventListener("mousemove", onDragMove);
  document.removeEventListener("mouseup", onDragEnd);
  document.removeEventListener("touchmove", onDragMove);
  document.removeEventListener("touchend", onDragEnd);
};

const computedMarks = computed(() => {
  if (!props.marks) return [];

  const result: Array<{ value: number; percent: number; label: string }> = [];

  for (
    let v = props.min;
    v <= props.max;
    v = +(v + props.interval).toFixed(10)
  ) {
    const markResult = props.marks(v);

    if (markResult && markResult.label) {
      result.push({
        value: v,
        percent: valueToPercent(v),
        label: markResult.label,
      });
    }
  }

  return result;
});

const dotPercent = computed(() => valueToPercent(currentValue.value));

const tooltipText = computed(() => {
  if (!props.tooltipFormatter) return undefined;
  return props.tooltipFormatter(currentValue.value);
});

const onKeydown = (event: KeyboardEvent) => {
  let newValue = currentValue.value;

  if (event.key === "ArrowRight" || event.key === "ArrowUp") {
    newValue = Math.min(props.max, currentValue.value + props.interval);
  } else if (event.key === "ArrowLeft" || event.key === "ArrowDown") {
    newValue = Math.max(props.min, currentValue.value - props.interval);
  } else if (event.key === "Home") {
    newValue = props.min;
  } else if (event.key === "End") {
    newValue = props.max;
  } else {
    return;
  }

  event.preventDefault();
  currentValue.value = +newValue.toFixed(10);
  emit("update:modelValue", currentValue.value);
  emit("change", currentValue.value);
};

onUnmounted(() => {
  document.removeEventListener("mousemove", onDragMove);
  document.removeEventListener("mouseup", onDragEnd);
  document.removeEventListener("touchmove", onDragMove);
  document.removeEventListener("touchend", onDragEnd);
});
</script>

<template>
  <div
    class="base-slider"
    :class="{ 'base-slider--dragging': isDragging }"
    role="slider"
    :aria-valuemin="props.min"
    :aria-valuemax="props.max"
    :aria-valuenow="currentValue"
    :aria-valuetext="tooltipText || String(currentValue)"
    tabindex="0"
    @keydown="onKeydown"
  >
    <div
      ref="railRef"
      class="base-slider__rail"
      @mousedown="onDragStart"
      @touchstart="onDragStart"
    >
      <div
        v-if="props.process"
        class="base-slider__process"
        :style="{ width: `${dotPercent}%` }"
      />

      <div
        v-for="mark in computedMarks"
        :key="mark.value"
        class="base-slider__mark"
        :style="{ left: `${mark.percent}%` }"
      >
        <div class="base-slider__mark-label">
          {{ mark.label }}
        </div>
      </div>

      <div
        class="base-slider__dot"
        :style="{
          left: `${dotPercent}%`,
          width: `${props.dotSize}px`,
          height: `${props.dotSize}px`,
        }"
      >
        <div class="base-slider__dot-handle" />
        <div v-if="tooltipText" class="base-slider__tooltip">
          <div class="base-slider__tooltip-inner">
            {{ tooltipText }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
