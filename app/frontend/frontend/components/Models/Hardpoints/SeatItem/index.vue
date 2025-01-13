<script lang="ts">
export default {
  name: "HardpointSeatItem",
};
</script>

<script lang="ts" setup>
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import { HardpointSourceEnum, type Hardpoint } from "@/services/fyApi";

type Props = {
  hardpoints: Hardpoint[];
};

const props = defineProps<Props>();

const hardpoint = computed(() => {
  return props.hardpoints[0];
});

const count = computed(() => {
  return props.hardpoints.length;
});

const name = computed(() => {
  return hardpoint.value.name
    .split("_")
    .join(" ")
    .replace("hardpoint", "")
    .replace(/\b\w/g, (l) => l.toUpperCase());
});
</script>

<template>
  <HardpointItem :count="count">
    <template #default>
      <HardpointComponent>
        <template v-if="hardpoint.source === HardpointSourceEnum.GAME_FILES">
          {{ name }}
        </template>
      </HardpointComponent>
    </template>
  </HardpointItem>
</template>
