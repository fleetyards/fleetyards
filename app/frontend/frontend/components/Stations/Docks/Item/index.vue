<template>
  <div>
    <div class="metrics-label">{{ docks.length }}x {{ size }}:</div>
    <div class="metrics-value">
      {{ sortedDocks.map((dock) => dock.name).join(", ") }}
    </div>
  </div>
</template>

<script lang="ts" setup>
import { sortBy } from "@/frontend/lib/Helpers";
import type { Dock } from "@/services/fyApi";

type Props = {
  docks: Dock[];
  size: number;
};

const props = defineProps<Props>();

const sortedDocks = computed(() => {
  return sortBy(props.docks, "name") as Dock[];
});
</script>

<script lang="ts">
export default {
  name: "StationsDocksItem",
};
</script>

<style lang="scss" scoped>
.dock-item {
  display: inline-block;
  padding-right: 5px;
  white-space: nowrap;
}
</style>
