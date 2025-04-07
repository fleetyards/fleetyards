<template>
  <div>
    {{ toTime(travelTime) }}
  </div>
</template>

<script lang="ts" setup>
import { type Component } from "@/services/fyApi";
import { calculateTravelTime } from "@/frontend/utils/travelTimes";
import { toTime } from "@/shared/utils/Time";

type Props = {
  quantumDrive: Component;
  distance: number;
};

const props = defineProps<Props>();

const stage1Acceleration = computed(() => {
  return (
    (props.quantumDrive.typeData?.standardJump.stage1AccelerationRate || 0) /
    1000
  );
});

const stage2Acceleration = computed(() => {
  return (
    (props.quantumDrive.typeData?.standardJump.stage2AccelerationRate || 0) /
    1000
  );
});

const speed = computed(() => {
  return (props.quantumDrive.typeData?.standardJump.speed || 0) / 1000;
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

<script lang="ts">
export default {
  name: "TravelTime",
};
</script>
