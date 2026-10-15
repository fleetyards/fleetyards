<script lang="ts">
export default {
  name: "VehicleEditModalPaint",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import VehiclePaintPicker from "@/frontend/components/Vehicles/PaintPicker/index.vue";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  FeatureFlagName,
  type Vehicle,
  useVehiclePaints,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { value: modelPaintIds, meta } = useField<string[]>("modelPaintIds");

const { isFeatureEnabled } = useFeatures();

// The pledge suggestion comes from the vehicle paints endpoint, which is part of
// the vehicle overview.
const { data: vehiclePaints } = useVehiclePaints(() => props.vehicle.id, {
  query: { enabled: isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW) },
});

const pledgedIds = computed(() =>
  (vehiclePaints.value || [])
    .filter((entry) => entry.pledged)
    .map((entry) => entry.paint.id),
);

// A ship that records no paint yet starts from what its owner's paint pledges
// resolve to. Only a suggestion: it saves with the rest of the form, or not.
watch(
  pledgedIds,
  (ids) => {
    if (!ids.length || meta.dirty || props.vehicle.modelPaintIds.length) {
      return;
    }

    modelPaintIds.value = [...ids];
  },
  { immediate: true },
);
</script>

<template>
  <VehiclePaintPicker
    v-model="modelPaintIds"
    :model-slug="vehicle.model.slug"
    :pledged-ids="pledgedIds"
    hide-legend
  />
</template>
