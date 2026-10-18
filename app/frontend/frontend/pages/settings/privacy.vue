<script lang="ts">
export default {
  name: "SettingsPrivacy",
};
</script>

<script lang="ts" setup>
import { useSessionStore } from "@/frontend/stores/session";
import { type UserUpdateInput } from "@/services/fyApi";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useForm } from "vee-validate";
import { useUpdateProfile as useUpdateProfileMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

const comlink = useComlink();

// RadioList speaks strings, and its reset entry is `undefined` -- which is how
// "as chosen when donating" travels until it is sent as `null`.
type PrivacyForm = Pick<UserUpdateInput, "tracking" | "showOnlineStatus"> & {
  supporterListed?: string;
};

const toSupporterListed = (value: boolean | null | undefined) =>
  value === null || value === undefined ? undefined : String(value);

const fromSupporterListed = (value: string | undefined) =>
  value === undefined ? null : value === "true";

// Defaults to the column default so the toggle never reads as "off" while the
// account is still loading, which would misstate whether visits are recorded.
const currentValues = (): PrivacyForm => ({
  tracking: sessionStore.currentUser?.tracking ?? true,
  showOnlineStatus: sessionStore.currentUser?.showOnlineStatus ?? true,
  supporterListed: toSupporterListed(sessionStore.currentUser?.supporterListed),
});

const { defineField, handleSubmit, resetForm, meta } = useForm<PrivacyForm>({
  initialValues: currentValues(),
});

// Re-seed the field itself rather than the initial values, which vee-validate
// has already copied: App.vue refreshes the account after boot, so the first
// render can be working from a stale persisted user. A pending choice wins over
// the refresh, otherwise a background refetch would silently revert it.
const setupForm = () => {
  if (meta.value.dirty) {
    return;
  }

  resetForm({ values: currentValues() });
};

onMounted(() => {
  if (sessionStore.currentUser) {
    setupForm();
  }
});

watch(
  () => sessionStore.currentUser,
  () => {
    setupForm();
  },
);

const [tracking, trackingProps] = defineField("tracking");
const [showOnlineStatus, showOnlineStatusProps] =
  defineField("showOnlineStatus");
const [supporterListed] = defineField("supporterListed");

const isSupporter = computed(() => !!sessionStore.currentUser?.supporter);

const supporterListedOptions = computed(() => [
  { label: t("labels.user.supporterListedShown"), value: "true" },
  { label: t("labels.user.supporterListedHidden"), value: "false" },
]);

const mutation = useUpdateProfileMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: {
        tracking: values.tracking,
        showOnlineStatus: values.showOnlineStatus,
        ...(isSupporter.value && {
          supporterListed: fromSupporterListed(values.supporterListed),
        }),
      },
    })
    .then(() => {
      // Saved values become the new baseline, so the refresh this triggers is
      // no longer treated as a pending choice. Safe to rebaseline from the
      // submitted values because the toggle is locked while the request is in
      // flight, so they cannot have drifted.
      resetForm({ values });

      comlink.emit("user-update");

      displaySuccess({
        text: t("messages.updatePrivacy.success"),
      });
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.privacy") }}</Heading>

  <form id="settings-privacy-form" @submit.prevent="onSubmit">
    <Panel>
      <PanelHeading :level="HeadingLevelEnum.H2">
        {{ t("headlines.settings.privacySections.analytics") }}
        <template #subtitle>
          {{ t("texts.settings.privacy.tracking") }}
        </template>
      </PanelHeading>
      <PanelBody>
        <FormToggle
          v-model="tracking"
          v-bind="trackingProps"
          name="tracking"
          :disabled="submitting"
          :label="t('labels.user.tracking')"
        />
      </PanelBody>
    </Panel>

    <Panel>
      <PanelHeading :level="HeadingLevelEnum.H2">
        {{ t("headlines.settings.privacySections.onlineStatus") }}
        <template #subtitle>
          {{ t("texts.settings.privacy.onlineStatus") }}
        </template>
      </PanelHeading>
      <PanelBody>
        <FormToggle
          v-model="showOnlineStatus"
          v-bind="showOnlineStatusProps"
          name="showOnlineStatus"
          :disabled="submitting"
          :label="t('labels.user.showOnlineStatus')"
        />
      </PanelBody>
    </Panel>

    <Panel v-if="isSupporter" data-test="supporter-listed">
      <PanelHeading :level="HeadingLevelEnum.H2">
        {{ t("headlines.settings.privacySections.supporters") }}
        <template #subtitle>
          {{ t("texts.settings.privacy.supporterListed") }}
        </template>
      </PanelHeading>
      <PanelBody>
        <RadioList
          v-model="supporterListed"
          name="supporterListed"
          :label="t('labels.user.supporterListed')"
          :reset-label="t('labels.user.supporterListedPlatform')"
          :options="supporterListedOptions"
          :disabled="submitting"
        />
      </PanelBody>
    </Panel>

    <FormActions
      :submitting="submitting"
      form-id="settings-privacy-form"
      hide-cancel
    />
  </form>
</template>
