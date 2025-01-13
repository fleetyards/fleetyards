<script lang="ts">
export default {
  name: "AdminModelEditFleetchartPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type ModelExtended, type ModelInput } from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormActions from "@/shared/components/base/FormActions/index.vue";
// import { useNoty } from "@/shared/composables/useNoty";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

// const { displayAlert } = useNoty();

const submitting = ref(false);

const initialValues = ref<ModelInput>({
  size: props.model.metrics.size,
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
  <Heading>{{ t("headlines.admin.models.edit.fleetchart") }}</Heading>
  <form @submit.prevent="onSubmit">
    <FormActions :submitting="submitting" @cancel="onCancel" />
  </form>
</template>
