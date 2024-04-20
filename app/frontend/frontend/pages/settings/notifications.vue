<script lang="ts">
export default {
  name: "SettingsNotificationsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Checkbox from "@/shared/components/base/Checkbox/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useSessionStore } from "@/frontend/stores/session";
import { useComlink } from "@/shared/composables/useComlink";
import { useForm } from "vee-validate";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { UserUpdateInput } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess } = useNoty();

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

const { users: usersService } = useApiClient();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await usersService.updateProfile({
      formData: values,
    });

    comlink.emit("user-update");

    displaySuccess({
      text: t("messages.updateNotifications.success"),
    });
  } catch (error) {
    console.error(error);
  }

  submitting.value = false;
});
</script>

<template>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-lg-12">
        <h1>{{ t("headlines.settings.notifications") }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <Checkbox
          v-model="saleNotify"
          v-bind="saleNotifyProps"
          :label="t('labels.user.saleNotify')"
          name="saleNotify"
        />
      </div>
    </div>
    <br />
    <Btn
      :loading="submitting"
      :type="BtnTypesEnum.SUBMIT"
      :size="BtnSizesEnum.LARGE"
    >
      {{ t("actions.save") }}
    </Btn>
  </form>
</template>
