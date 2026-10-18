<script lang="ts">
export default {
  name: "VehicleLogEntryModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormMarkdownEditor from "@/shared/components/base/FormMarkdownEditor/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type Vehicle,
  type VehicleLogEntry,
  useCreateVehicleLogEntry,
  useUpdateVehicleLogEntry,
  getVehicleLogEntriesQueryKey,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
  logEntry?: VehicleLogEntry;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const queryClient = useQueryClient();

const isEdit = computed(() => !!props.logEntry);

const initialValues = {
  title: props.logEntry?.title ?? "",
  body: props.logEntry?.body ?? "",
  loggedAt: (props.logEntry?.loggedAt ?? null) as string | null,
  public: props.logEntry?.public ?? props.vehicle.logEntriesPublicByDefault,
};

const { defineField, handleSubmit, values } = useForm({
  initialValues,
});

useModalDirty(useFormDirty(values, initialValues));

const [title, titleProps] = defineField("title");
const [body, bodyProps] = defineField("body");
const [loggedAt, loggedAtProps] = defineField("loggedAt");
const [isPublic] = defineField("public");

// The date field hands back local time without an offset, which the API's
// date-time format rejects. Left empty on a new entry, the server dates it.
const toIso = (value: string | null) => {
  if (!value) return undefined;

  const parsed = new Date(value);

  return isNaN(parsed.getTime()) ? undefined : parsed.toISOString();
};

const invalidateLog = () =>
  queryClient.invalidateQueries({
    queryKey: getVehicleLogEntriesQueryKey(props.vehicle.id),
  });

const createMutation = useCreateVehicleLogEntry();
const updateMutation = useUpdateVehicleLogEntry();

const submitting = computed(
  () => createMutation.isPending.value || updateMutation.isPending.value,
);

const onSubmit = handleSubmit(async (values) => {
  const data = {
    title: values.title,
    body: values.body || null,
    loggedAt: toIso(values.loggedAt),
    public: values.public,
  };

  const mutation = props.logEntry
    ? updateMutation.mutateAsync({
        vehicleId: props.vehicle.id,
        id: props.logEntry.id,
        data,
      })
    : createMutation.mutateAsync({ vehicleId: props.vehicle.id, data });

  await mutation
    .then(async () => {
      await invalidateLog();

      displaySuccess({
        text: isEdit.value
          ? t("messages.vehicleLog.update.success")
          : t("messages.vehicleLog.create.success"),
      });
      comlink.emit("close-modal", true);
    })
    .catch(() => {
      displayAlert({
        text: isEdit.value
          ? t("messages.vehicleLog.update.failure")
          : t("messages.vehicleLog.create.failure"),
      });
    });
});
</script>

<template>
  <Modal
    :title="
      isEdit ? t('headlines.vehicleLog.edit') : t('headlines.vehicleLog.create')
    "
  >
    <form id="vehicle-log-entry-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="title"
        v-bind="titleProps"
        name="title"
        rules="required|max:255"
        :label="t('labels.vehicleLog.title')"
        data-test="vehicle-log-entry-title"
      />
      <FormDateTime
        v-model="loggedAt"
        v-bind="loggedAtProps"
        name="loggedAt"
        :clearable="!isEdit"
        :label="t('labels.vehicleLog.loggedAt')"
        :placeholder="t('labels.vehicleLog.loggedAtPlaceholder')"
      />
      <FormMarkdownEditor
        v-model="body"
        v-bind="bodyProps"
        name="body"
        :label="t('labels.vehicleLog.body')"
      />
      <FormToggle
        v-model="isPublic"
        name="public"
        :label="t('labels.vehicleLog.public')"
        data-test="vehicle-log-entry-public"
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="vehicle-log-entry-form"
        :loading="submitting"
        data-test="vehicle-log-entry-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
