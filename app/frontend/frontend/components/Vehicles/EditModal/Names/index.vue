<script lang="ts">
export default {
  name: "VehicleEditModalNames",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";
import AlternativeNamesInput from "./AlternativeNamesInput/index.vue";
import { useRule as useVehicleSerialRule } from "@/frontend/validations/rules/vehicleSerial";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { value: name } = useField<string | null | undefined>("name");
const { value: alternativeNames } = useField<string[]>("alternativeNames");

const validateSerial = useVehicleSerialRule();

// Saving strips and upcases a serial before it compares it with the stored
// one, so `sub flagship` retyped over `SUB FLAGSHIP` is no change either.
function sameSerial(value?: string | null, saved?: string | null) {
  return (value ?? "").trim().toUpperCase() === (saved ?? "");
}

// The server only checks a serial that changed, so one from before the game
// format can stay while the name is edited.
const serialRules = (
  value: string | number | null,
  ctx: FieldValidationMetaInfo,
) =>
  sameSerial(value?.toString(), props.vehicle.serial) ||
  validateSerial(value?.toString(), [undefined], ctx);

const useName = (newName: string) => {
  name.value = newName;
};
</script>

<template>
  <div>
    <div class="row">
      <div class="col-12 col-md-6">
        <div class="form-group">
          <FormInput
            v-model="name"
            name="name"
            :placeholder="vehicle.model?.name"
            translation-key="name"
            :no-label="true"
          />
        </div>
      </div>
      <div class="col-12 col-md-6">
        <div class="form-group">
          <FormInput
            name="serial"
            :rules="serialRules"
            :placeholder="t('placeholders.vehicle.serial')"
            translation-key="vehicle.serial"
            :no-label="true"
          />
        </div>
      </div>
    </div>
    <AlternativeNamesInput
      v-model="alternativeNames"
      name="alternativeNames"
      :current-name="name"
      @use-name="useName"
    />
  </div>
</template>
