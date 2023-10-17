<template>
  <div class="metrics-list">
    <div
      v-for="metric in metrics"
      :key="key(metric.id)"
      class="metrics-list-item"
    >
      <div class="metrics-list-item-label">{{ metric.label }}:</div>
      <div class="metrics-list-item-value">
        {{ metric.value }}
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";

type Metric = {
  id: string;
  label: string;
  value: string;
};

type Props = {
  metrics: Metric[];
};

defineProps<Props>();

const uuid = ref(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const key = (id: string) => `metric-${uuid.value}-${id}`;
</script>

<script lang="ts">
export default {
  name: "MetricsList",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
