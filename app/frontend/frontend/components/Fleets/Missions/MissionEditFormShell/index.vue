<script lang="ts">
export default {
  name: "FleetMissionEditFormShell",
};
</script>

<script lang="ts" setup>
import { type SubmissionHandler } from "vee-validate";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  type Fleet,
  type MissionExtended,
  type MissionUpdateInput,
  type ValidationError,
  useUpdateFleetMission,
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
  mission: MissionExtended;
  handleSubmit: (
    cb: SubmissionHandler<MissionUpdateInput>,
  ) => (event?: Event) => Promise<unknown>;
  meta: FormMeta;
  setErrors?: SetErrors;
  formId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  setErrors: undefined,
  formId: "fleet-mission-edit-form",
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const submitting = ref(false);
const updateMutation = useUpdateFleetMission();

const onSubmit = props.handleSubmit(async (values) => {
  submitting.value = true;
  try {
    await updateMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.mission.slug,
      data: values,
    });
    displaySuccess({ text: t("messages.fleets.mission.update.success") });
    comlink.emit("fleet-mission-updated");
  } catch (error) {
    const response = (error as AxiosError<ValidationError>).response;
    if (response?.data?.errors && props.setErrors) {
      props.setErrors(transformErrors(response.data.errors));
    }
    displayAlert({
      text:
        response?.data?.message || t("messages.fleets.mission.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});

const handleCancel = () => {
  void router.push({
    name: "fleet-mission",
    params: { slug: props.fleet.slug, mission: props.mission.slug },
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
