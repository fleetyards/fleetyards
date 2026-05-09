<script lang="ts">
export default {
  name: "AdminModelEditCargoAndFuelPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import ModelForm from "@/admin/components/Models/Form/index.vue";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const initialValues = ref<ModelUpdateInput>({
  hydrogenFuelTankSize: props.model.metrics.hydrogenFuelTankSize,
  quantumFuelTankSize: props.model.metrics.quantumFuelTankSize,
});

const validationSchema = {};

const { defineField, handleSubmit, meta } = useForm<ModelUpdateInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [hydrogenFuelTankSize, hydrogenFuelTankSizeProps] = defineField(
  "hydrogenFuelTankSize",
);
const [quantumFuelTankSize, quantumFuelTankSizeProps] = defineField(
  "quantumFuelTankSize",
);
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.cargoAndFuel") }}</Heading>
  <ModelForm :model="model" :handle-submit="handleSubmit" :meta="meta">
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
  </ModelForm>
</template>

<style lang="scss" scoped>
@import "cargo-and-fuel";
</style>
