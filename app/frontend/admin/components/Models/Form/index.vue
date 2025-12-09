<script lang="ts">
export default {
  name: "ModelsForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useModelUpdateMutation } from "@/admin/composables/useModelUpdateMutation";
import {
  type ModelCreateInput,
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";

type Props = {
  model: ModelExtended;
  validationSchema?: Record<string, any>;
  initialValues?: MaybeRef<ModelUpdateInput | ModelCreateInput>;
};

const props = defineProps<Props>();

const {
  handleSubmit: handleFormSubmit,
  meta,
  setErrors,
} = useForm<ModelUpdateInput>({
  initialValues: unref(props.initialValues),
  validationSchema: props.validationSchema,
});

const submitting = ref(false);

const { updateMutation: mutation } = useModelUpdateMutation(props.model);

const onSubmit = handleFormSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      id: props.model.id,
      data: values,
    })
    .catch((error) => {
      // Handle error (e.g., display notification)
      console.error("Error updating model:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = () => {
  redirectBack();
};

const { extend } = useBreadCrumbs();

const router = useRouter();

const backRoute = computed(() => ({
  name: "admin-models",
  hash: `#${props.model.id}`,
}));

const redirectBack = () => {
  router.push(extend(backRoute.value));
};
</script>

<template>
  <form @submit.prevent="onSubmit" id="admin-models-form">
    <slot />
    <FormActions
      :submitting="submitting"
      formId="admin-models-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
