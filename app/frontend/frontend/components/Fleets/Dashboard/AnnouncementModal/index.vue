<script lang="ts">
export default {
  name: "FleetDashboardAnnouncementModal",
};
</script>

<script lang="ts" setup>
import { addDays } from "date-fns";
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormMarkdownEditor from "@/shared/components/base/FormMarkdownEditor/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnTypesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  getFleetAnnouncementsQueryKey,
  useCreateFleetAnnouncement,
  useDestroyFleetAnnouncement,
  useUpdateFleetAnnouncement,
  type FilterOption,
  type FleetAnnouncement,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  announcement?: FleetAnnouncement;
};

const props = withDefaults(defineProps<Props>(), {
  announcement: undefined,
});

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const comlink = useComlink();

const queryClient = useQueryClient();

const BODY_LIMIT = 2000;

// How long it stands, picked as a span rather than a date: "for a week" is
// what an officer means, and a span needs no time zone to be right.
const KEEP = "keep";

// Only while that end is still ahead: keeping one that has passed would save
// an announcement nobody sees.
const canKeep = computed(
  () =>
    !!props.announcement?.expiresAt &&
    new Date(props.announcement.expiresAt).getTime() > Date.now(),
);

const expiryOptions = computed<FilterOption[]>(() => [
  ...(canKeep.value
    ? [{ label: t("fleetDashboard.announcements.expiry.keep"), value: KEEP }]
    : []),
  { label: t("fleetDashboard.announcements.expiry.never"), value: "0" },
  { label: t("fleetDashboard.announcements.expiry.day"), value: "1" },
  { label: t("fleetDashboard.announcements.expiry.days3"), value: "3" },
  { label: t("fleetDashboard.announcements.expiry.week"), value: "7" },
  { label: t("fleetDashboard.announcements.expiry.weeks2"), value: "14" },
]);

type FormValues = { body: string; expiry: string };

const { defineField, handleSubmit, setErrors } = useForm<FormValues>({
  initialValues: {
    body: props.announcement?.body ?? "",
    expiry: canKeep.value ? KEEP : "0",
  },
});

const [body, bodyProps] = defineField("body");

const [expiry, expiryProps] = defineField("expiry");

const expiresAtFor = (value: string) => {
  if (value === KEEP) return undefined;

  const days = Number(value);

  return days > 0 ? addDays(new Date(), days).toISOString() : null;
};

const createMutation = useCreateFleetAnnouncement();

const updateMutation = useUpdateFleetAnnouncement();

const destroyMutation = useDestroyFleetAnnouncement();

const submitting = ref(false);

const formId = computed(
  () => `fleet-announcement-${props.announcement?.id ?? "new"}`,
);

const done = (message: string) => {
  void queryClient.invalidateQueries({
    queryKey: getFleetAnnouncementsQueryKey(props.fleetSlug),
  });
  comlink.emit("close-modal");
  displaySuccess({ text: message });
};

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = { body: values.body, expiresAt: expiresAtFor(values.expiry) };

  try {
    if (props.announcement) {
      await updateMutation.mutateAsync({
        fleetSlug: props.fleetSlug,
        id: props.announcement.id,
        data,
      });
    } else {
      await createMutation.mutateAsync({ fleetSlug: props.fleetSlug, data });
    }

    done(t("fleetDashboard.announcements.messages.saved"));
  } catch (error) {
    const { message, formErrors } = validationErrorFrom(error);

    setErrors(formErrors);
    displayAlert({
      text: message || t("fleetDashboard.announcements.messages.saveFailed"),
    });
  } finally {
    submitting.value = false;
  }
});

const remove = async () => {
  if (!props.announcement) return;

  submitting.value = true;

  try {
    await destroyMutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      id: props.announcement.id,
    });

    done(t("fleetDashboard.announcements.messages.removed"));
  } catch {
    displayAlert({
      text: t("fleetDashboard.announcements.messages.removeFailed"),
    });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal
    :title="
      announcement
        ? t('fleetDashboard.announcements.edit')
        : t('fleetDashboard.announcements.post')
    "
  >
    <form :id="formId" @submit.prevent="onSubmit">
      <FormMarkdownEditor
        v-model="body"
        v-bind="bodyProps"
        name="body"
        rules="required"
        :maxlength="BODY_LIMIT"
        :label="t('fleetDashboard.announcements.body')"
      />
      <BaseSelect
        v-model="expiry"
        v-bind="expiryProps"
        name="expiry"
        :options="expiryOptions"
        :label="t('fleetDashboard.announcements.expiry.label')"
        :searchable="false"
        unsorted
      />
    </form>
    <template #footer>
      <Btn
        :size="BtnSizesEnum.LG"
        :variant="BtnVariantsEnum.BARE"
        @click="comlink.emit('close-modal')"
      >
        {{ t("actions.cancel") }}
      </Btn>
      <Btn
        v-if="announcement"
        :size="BtnSizesEnum.LG"
        :tone="BtnTonesEnum.DANGER"
        :disabled="submitting"
        :confirm="t('fleetDashboard.announcements.confirmRemove')"
        data-test="fleet-announcement-remove"
        @click="remove"
      >
        {{ t("actions.delete") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.LG"
        :type="BtnTypesEnum.SUBMIT"
        :form="formId"
        :loading="submitting"
        data-test="fleet-announcement-save"
      >
        {{
          announcement
            ? t("actions.save")
            : t("fleetDashboard.announcements.postAction")
        }}
      </Btn>
    </template>
  </Modal>
</template>
