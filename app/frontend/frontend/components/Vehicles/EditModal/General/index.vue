<script lang="ts">
export default {
  name: "VehicleEditModalGeneral",
};
</script>

<script lang="ts" setup>
import { useField, useFormValues } from "vee-validate";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useVehicleBoughtViaFilters as useVehicleBoughtViaFiltersQuery,
  type Vehicle,
  type VehicleUpdateInput,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const values = useFormValues<VehicleUpdateInput>();

const { value: boughtVia } =
  useField<VehicleUpdateInput["boughtVia"]>("boughtVia");

const { data: boughtViaFilters } = useVehicleBoughtViaFiltersQuery();

// There is no pledge store to have bought an in-game-only ship from, and the
// server rewrites the value anyway -- offering the choice would only let
// someone pick an answer that never survives the save.
const boughtViaOptions = computed(() => {
  if (!props.vehicle.model?.ingameOnly) {
    return boughtViaFilters.value;
  }

  return (boughtViaFilters.value || []).filter(
    (option) => option.value === "ingame",
  );
});
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-6">
      <div class="form-group">
        <BaseSelect
          :key="`bought-via-${vehicle.model?.id}`"
          v-model="boughtVia"
          :options="boughtViaOptions"
          :label="t('labels.vehicle.boughtViaSelect.label')"
          name="boughtVia"
          :nullable="false"
        />
      </div>
    </div>
    <div class="col-12 col-md-6">
      <FormToggle
        name="flagship"
        :model-value="values.flagship"
        :label="t('labels.vehicle.flagship')"
        align-with-fields
      />
    </div>
  </div>
</template>
