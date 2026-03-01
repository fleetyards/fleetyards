<script lang="ts">
export default {
  name: "TravelTime",
};
</script>

<script lang="ts" setup>
import { type Component, type ComponentQuantumDrive } from "@/services/fyApi";
import { calculateTravelTime } from "@/frontend/utils/travelTimes";
import { toTime } from "@/shared/utils/Time";

type Props = {
  quantumDrive: Component;
  distance: number;
};

const props = defineProps<Props>();

const typeData = computed(
  () => props.quantumDrive.typeData as ComponentQuantumDrive | undefined,
);

const stage1Acceleration = computed(() => {
  return (typeData.value?.standardJump.stage1AccelerationRate || 0) / 1000;
});

const stage2Acceleration = computed(() => {
  return (typeData.value?.standardJump.stage2AccelerationRate || 0) / 1000;
});

const speed = computed(() => {
  return (typeData.value?.standardJump.speed || 0) / 1000;
});

const travelTime = computed(() => {
  return calculateTravelTime(
    stage1Acceleration.value,
    stage2Acceleration.value,
    speed.value,
    props.distance,
  );
});
</script>

<template>
  <div>
    {{ toTime(travelTime) }}
  </div>
</template>
