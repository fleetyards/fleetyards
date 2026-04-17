<script lang="ts">
export default {
  name: "ChangePasswordForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useRouter } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import type { PasswordInput } from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import {
  BtnVariantsEnum,
  BtnTypesEnum,
} from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useSessionStore } from "@/frontend/stores/session";

import { useUpdatePassword as useUpdatePasswordMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const sessionStore = useSessionStore();

const isOauthOnly = computed(
  () => sessionStore.currentUser?.oauthOnly ?? false,
);

const validationSchema = computed(() => ({
  currentPassword: isOauthOnly.value ? "" : "required",
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:@password",
}));

const initialValues = ref<PasswordInput>({
  currentPassword: undefined,
  password: undefined,
  passwordConfirmation: undefined,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [currentPassword, currentPasswordProps] = defineField("currentPassword");
const [password, passwordProps] = defineField("password");
const [passwordConfirmation, passwordConfirmationProps] = defineField(
  "passwordConfirmation",
);

const submitting = ref(false);

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  initialValues.value = {
    currentPassword: undefined,
    password: undefined,
    passwordConfirmation: undefined,
  };
};

const router = useRouter();

const mutation = useUpdatePasswordMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = isOauthOnly.value
    ? { password: values.password, passwordConfirmation: values.passwordConfirmation }
    : values;

  await mutation
    .mutateAsync({
      data,
    })
    .then(async () => {
      displaySuccess({
        text: t("messages.changePassword.success"),
      });

      await router.push("/").catch(() => {});
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.changePassword.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <form @submit.prevent="onSubmit">
    <FormInput
      v-if="!isOauthOnly"
      v-model="currentPassword"
      name="currentPassword"
      :rules="validationSchema.currentPassword"
      :label="t('labels.currentPassword')"
      v-bind="currentPasswordProps"
      :type="InputTypesEnum.PASSWORD"
    />

    <FormInput
      v-model="password"
      name="password"
      :rules="validationSchema.password"
      v-bind="passwordProps"
      :label="t('labels.password')"
      :type="InputTypesEnum.PASSWORD"
    />

    <FormInput
      v-model="passwordConfirmation"
      name="passwordConfirmation"
      :rules="validationSchema.passwordConfirmation"
      v-bind="passwordConfirmationProps"
      :label="t('labels.passwordConfirmation')"
      :type="InputTypesEnum.PASSWORD"
    />
    <div class="flex">
      <Btn :loading="submitting" :type="BtnTypesEnum.SUBMIT">
        {{ isOauthOnly ? t("actions.setPassword") : t("actions.updatePassword") }}
      </Btn>
      <Btn
        v-if="!isOauthOnly"
        :to="{ name: 'request-password' }"
        :variant="BtnVariantsEnum.LINK"
      >
        {{ t("actions.reset-password") }}
      </Btn>
    </div>
  </form>
</template>
