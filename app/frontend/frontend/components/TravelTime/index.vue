<script lang="ts">
export default {
  name: "TravelTime",
};
</script>

<script lang="ts" setup>
import { type Component } from "@/services/fyApi";
import { quantumDriveTravelTime } from "@/frontend/utils/travelTimes";
import { toTime } from "@/shared/utils/Time";

type Props = {
  quantumDrive: Component;
  distance: number;
};

const props = defineProps<Props>();

const travelTime = computed(() =>
  quantumDriveTravelTime(props.quantumDrive, props.distance),
);
</script>

<template>
  <div>
    {{ toTime(travelTime) }}
  </div>
</template>
