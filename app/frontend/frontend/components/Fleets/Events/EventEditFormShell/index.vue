<script lang="ts">
export default {
  name: "FleetEventEditFormShell",
};
</script>

<script lang="ts" setup>
import { type SubmissionHandler } from "vee-validate";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  type Fleet,
  type FleetEventExtended,
  type FleetEventUpdateInput,
  type ValidationError,
  useUpdateFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { transformErrors } from "@/frontend/utils/transformErrors";
import { type AxiosError } from "axios";

type FormMeta = {
  dirty: boolean;
  touched: boolean;
};

type SetErrors = (
  fields: Record<string, string | string[] | undefined>,
) => void;

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
  handleSubmit: (
    cb: SubmissionHandler<FleetEventUpdateInput>,
  ) => (event?: Event) => Promise<unknown>;
  meta: FormMeta;
  setErrors?: SetErrors;
  formId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  setErrors: undefined,
  formId: "fleet-event-edit-form",
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const submitting = ref(false);
const updateMutation = useUpdateFleetEvent();

const onSubmit = props.handleSubmit(async (values) => {
  submitting.value = true;
  try {
    await updateMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.event.slug,
      data: values,
    });
    displaySuccess({ text: t("messages.fleets.event.update.success") });
    comlink.emit("fleet-event-updated");
  } catch (error) {
    const response = (error as AxiosError<ValidationError>).response;
    if (response?.data?.errors && props.setErrors) {
      props.setErrors(transformErrors(response.data.errors));
    }
    displayAlert({
      text:
        response?.data?.message || t("messages.fleets.event.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});

const router = useRouter();

const handleCancel = () => {
  void router.push({
    name: "fleet-event",
    params: { slug: props.fleet.slug, event: props.event.slug },
  });
};
</script>

<template>
  <form :id="formId" @submit.prevent="onSubmit">
    <slot />
    <FormActions
      :submitting="submitting"
      :form-id="formId"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
