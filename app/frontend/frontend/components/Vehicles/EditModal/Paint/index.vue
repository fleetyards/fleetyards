<script lang="ts">
export default {
  name: "VehicleEditModalPaint",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import VehiclePaintPicker from "@/frontend/components/Vehicles/PaintPicker/index.vue";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

defineProps<Props>();

const { value: modelPaintId } = useField<string | null>("modelPaintId");
</script>

<template>
  <VehiclePaintPicker
    v-model="modelPaintId"
    :model-slug="vehicle.model.slug"
    :default-image="vehicle.model.media.storeImage?.smallUrl"
    hide-legend
  />
</template>
