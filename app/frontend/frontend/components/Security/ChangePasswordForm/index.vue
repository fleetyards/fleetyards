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
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";

import { useUpdatePassword as useUpdatePasswordMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const validationSchema = {
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:@password",
};

const initialValues = ref<PasswordInput>({
  password: undefined,
  passwordConfirmation: undefined,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

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
    password: undefined,
    passwordConfirmation: undefined,
  };
};

const router = useRouter();

const mutation = useUpdatePasswordMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: {
        password: values.password,
        passwordConfirmation: values.passwordConfirmation,
      },
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
        {{ t("actions.updatePassword") }}
      </Btn>
    </div>
  </form>
</template>
