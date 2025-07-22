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
import FormActions from "@/shared/components/base/FormActions/index.vue";
// import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

// const { displayAlert } = useAppNotifications();

const submitting = ref(false);

const initialValues = ref<ModelUpdateInput>({
  size: props.model.metrics.size,
  length: props.model.metrics.length,
  beam: props.model.metrics.beam,
  height: props.model.metrics.height,
});

const validationSchema = {};

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [size, sizeProps] = defineField("size");

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  console.info(values);
});

const onCancel = () => {
  alert("cancel");
};
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.hardpoints") }}</Heading>
  <form @submit.prevent="onSubmit">
    <FormActions :submitting="submitting" @cancel="onCancel" />
  </form>
</template>
