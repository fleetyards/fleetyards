<script lang="ts">
export default {
  name: "SettingsNotificationsPage",
};
</script>

<script lang="ts" setup>
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { useComlink } from "@/shared/composables/useComlink";
import { useForm } from "vee-validate";
import { UserUpdateInput } from "@/services/fyApi";
import { useUpdateProfile as useUpdateProfileMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

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

const setupForm = () => {
  initialValues.value = {
    saleNotify: sessionStore.currentUser?.saleNotify,
  };
};

const comlink = useComlink();

const initialValues = ref<UserUpdateInput>({
  saleNotify: sessionStore.currentUser?.saleNotify,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [saleNotify, saleNotifyProps] = defineField("saleNotify");

const mutation = useUpdateProfileMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
    })
    .then(() => {
      comlink.emit("user-update");

      displaySuccess({
        text: t("messages.updateNotifications.success"),
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
  <form id="settings-notifications-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-lg-12">
        <h1>{{ t("headlines.settings.notifications") }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="saleNotify"
          v-bind="saleNotifyProps"
          :label="t('labels.user.saleNotify')"
          name="saleNotify"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="settings-notifications-form"
      hide-cancel
    />
  </form>
</template>
