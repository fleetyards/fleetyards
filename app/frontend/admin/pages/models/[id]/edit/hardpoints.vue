<script lang="ts">
export default {
  name: "AdminModelEditHardpointsPage",
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
import ModelForm from "@/admin/components/Models/Form/index.vue";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const initialValues = ref<ModelUpdateInput>({
  size: props.model.metrics.size,
  length: props.model.metrics.length,
  beam: props.model.metrics.beam,
  height: props.model.metrics.height,
});

const validationSchema = {};

const { defineField } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

// const [size, sizeProps] = defineField("size");
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.hardpoints") }}</Heading>
  <ModelForm
    :model="model"
    :validation-schema="validationSchema"
    :initial-values="initialValues"
  >
  </ModelForm>
</template>
