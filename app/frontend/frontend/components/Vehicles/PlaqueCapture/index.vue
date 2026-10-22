<script lang="ts">
export default {
  name: "VehiclePlaqueCapture",
};
</script>

<script lang="ts" setup>
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
  captain?: string;
};

const props = withDefaults(defineProps<Props>(), {
  captain: undefined,
});

// Drawn as the public sees it, since anyone a shared link reaches gets the
// picture: a name and serial the owner keeps to themselves stay off it.
const publicVehicle = computed<Vehicle>(() => ({
  ...props.vehicle,
  id: `${props.vehicle.id}-capture`,
  name: props.vehicle.nameVisible ? props.vehicle.name : undefined,
  serial: props.vehicle.nameVisible ? props.vehicle.serial : undefined,
}));

const root = ref<HTMLElement>();

defineExpose({
  plaque: () => root.value?.querySelector<HTMLElement>(".vehicle-plaque"),
});
</script>

<template>
  <!-- Off screen at a fixed width, so the picture is the same whatever the
       screen the plaque was saved on. -->
  <div ref="root" class="plaque-capture" aria-hidden="true">
    <VehiclePlaque :vehicle="publicVehicle" :captain="captain" />
  </div>
</template>

<style lang="scss" scoped>
.plaque-capture {
  position: fixed;
  top: 0;
  left: -10000px;
  width: 800px;
  pointer-events: none;
}
</style>
