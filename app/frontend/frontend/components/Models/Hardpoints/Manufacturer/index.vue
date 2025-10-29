<script lang="ts">
export default {
  name: "HardpointManufacturer",
};
</script>

<script lang="ts" setup>
import { type Manufacturer } from "@/services/fyApi";

type Props = {
  manufacturer?: Manufacturer;
};

withDefaults(defineProps<Props>(), {
  manufacturer: undefined,
});
</script>

<template>
  <!-- eslint-disable vue/no-v-html -->
  <div
    v-if="manufacturer"
    class="hardpoint-item__component-manufacturer"
    v-html="manufacturer.name"
  />
  <!-- eslint-enable vue/no-v-html -->
</template>
