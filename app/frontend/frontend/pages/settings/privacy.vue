<script lang="ts">
export default {
  name: "SettingsPrivacy",
};
</script>

<script lang="ts" setup>
import { useSessionStore } from "@/frontend/stores/session";
import { type UserUpdateInput } from "@/services/fyApi";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
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

// Defaults to the column default so the toggle never reads as "off" while the
// account is still loading, which would misstate whether visits are recorded.
const currentValues = (): UserUpdateInput => ({
  tracking: sessionStore.currentUser?.tracking ?? true,
});

const { defineField, handleSubmit, resetForm, meta } = useForm<UserUpdateInput>(
  {
    initialValues: currentValues(),
  },
);

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

const mutation = useUpdateProfileMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
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
    <div class="row">
      <div class="col-12">
        <p>{{ t("texts.settings.privacy.tracking") }}</p>
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="tracking"
          v-bind="trackingProps"
          name="tracking"
          :disabled="submitting"
          :label="t('labels.user.tracking')"
        />
      </div>
    </div>

    <FormActions
      :submitting="submitting"
      form-id="settings-privacy-form"
      hide-cancel
    />
  </form>
</template>
