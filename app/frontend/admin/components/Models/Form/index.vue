<script lang="ts">
export default {
  name: "ModelsForm",
};
</script>

<script lang="ts" setup>
import { type SubmissionHandler } from "vee-validate";
import { useModelUpdateMutation } from "@/admin/composables/useModelUpdateMutation";
import {
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";

type FormMeta = {
  dirty: boolean;
  touched: boolean;
};

type SetErrors = (
  fields: Record<string, string | string[] | undefined>,
) => void;

type Props = {
  model: ModelExtended;
  handleSubmit: (
    cb: SubmissionHandler<ModelUpdateInput>,
  ) => (event?: Event) => Promise<unknown>;
  meta: FormMeta;
  setErrors?: SetErrors;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();

const submitting = ref(false);

const { updateMutation: mutation } = useModelUpdateMutation(props.model);

const onSubmit = props.handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      id: props.model.id,
      data: values,
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      props.setErrors?.(formErrors);

      displayAlert({
        text: message || t("errors.generic"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await redirectBack();
};

const { extend } = useBreadCrumbs();

const router = useRouter();

const backRoute = computed(() => ({
  name: "admin-models",
  hash: `#${props.model.id}`,
}));

const redirectBack = async () => {
  await router.push(extend(backRoute.value));
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
