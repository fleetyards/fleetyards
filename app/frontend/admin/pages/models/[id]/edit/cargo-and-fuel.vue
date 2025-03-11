<script lang="ts">
export default {
  name: "AdminModelEditCargoAndFuelPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type ModelExtended, type ModelInput } from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const submitting = ref(false);

const initialValues = ref<ModelInput>({
  cargo: props.model.metrics.cargo,
  hydrogenFuelTankSize: props.model.metrics.hydrogenFuelTankSize,
  quantumFuelTankSize: props.model.metrics.quantumFuelTankSize,
});

const validationSchema = {};

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [cargo, cargoProps] = defineField("cargo");
const [hydrogenFuelTankSize, hydrogenFuelTankSizeProps] = defineField(
  "hydrogenFuelTankSize",
);
const [quantumFuelTankSize, quantumFuelTankSizeProps] = defineField(
  "quantumFuelTankSize",
);

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  console.info(values);
});

const onCancel = () => {
  displayAlert({ text: "cancel" });
};
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.cargoAndFuel") }}</Heading>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="cargo"
          v-bind="cargoProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="cargo"
          :type="InputTypesEnum.NUMBER"
          translation-key="model.cargo"
          :suffix="t('number.units.cargo')"
        />
        <FormTextarea
          v-if="model.cargoHolds"
          :model-value="JSON.stringify(model.cargoHolds, undefined, 4)"
          name="cargoHolds"
          translation-key="model.cargoHolds"
          class="base-data-output"
          disabled
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="hydrogenFuelTankSize"
          v-bind="hydrogenFuelTankSizeProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="hydrogenFuelTankSize"
          :type="InputTypesEnum.NUMBER"
          translation-key="model.hydrogenFuelTankSize"
          :suffix="t('number.units.cargo')"
        />
        <FormTextarea
          v-if="model.hydrogenFuelTanks"
          :model-value="JSON.stringify(model.hydrogenFuelTanks, undefined, 4)"
          name="hydrogenFuelTanks"
          translation-key="model.hydrogenFuelTanks"
          class="base-data-output"
          disabled
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="quantumFuelTankSize"
          v-bind="quantumFuelTankSizeProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="quantumFuelTankSize"
          :type="InputTypesEnum.NUMBER"
          translation-key="model.quantumFuelTankSize"
          :suffix="t('number.units.cargo')"
        />
        <FormTextarea
          v-if="model.quantumFuelTanks"
          :model-value="JSON.stringify(model.quantumFuelTanks, undefined, 4)"
          name="quantumFuelTanks"
          translation-key="model.quantumFuelTanks"
          class="base-data-output"
          disabled
        />
      </div>
    </div>
    <FormActions :submitting="submitting" @cancel="onCancel" />
  </form>
</template>

<style lang="scss" scoped>
@import "cargo-and-fuel";
</style>
