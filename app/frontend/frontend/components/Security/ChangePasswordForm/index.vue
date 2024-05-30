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
import { useApiClient } from "@/frontend/composables/useApiClient";
import type { PasswordInput } from "@/services/fyApi";
import { useNoty } from "@/shared/composables/useNoty";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import {
  BtnVariantsEnum,
  BtnTypesEnum,
} from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty();

const validationSchema = {
  currentPassword: "required",
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:password",
};

const initialValues = ref<PasswordInput>({
  currentPassword: undefined,
  password: undefined,
  passwordConfirmation: undefined,
});

const { defineField, handleSubmit } = useForm({
  validationSchema,
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

const { password: passwordService } = useApiClient();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await passwordService.updatePassword({
      requestBody: values,
    });

    displaySuccess({
      text: t("messages.changePassword.success"),
    });

    router.push("/");
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.changePassword.failure"),
    });
  }

  submitting.value = false;
});
</script>

<template>
  <form @submit.prevent="onSubmit">
    <FormInput
      v-model="currentPassword"
      name="currentPassword"
      :label="t('labels.currentPassword')"
      v-bind="currentPasswordProps"
      :type="InputTypesEnum.PASSWORD"
    />

    <FormInput
      v-model="password"
      name="password"
      v-bind="passwordProps"
      :label="t('labels.password')"
      :type="InputTypesEnum.PASSWORD"
    />

    <FormInput
      v-model="passwordConfirmation"
      name="passwordConfirmation"
      v-bind="passwordConfirmationProps"
      :label="t('labels.passwordConfirmation')"
      :type="InputTypesEnum.PASSWORD"
    />
    <div class="d-flex">
      <Btn :loading="submitting" :type="BtnTypesEnum.SUBMIT">
        {{ t("actions.updatePassword") }}
      </Btn>
      <Btn :to="{ name: 'request-password' }" :variant="BtnVariantsEnum.LINK">
        {{ t("actions.reset-password") }}
      </Btn>
    </div>
  </form>
</template>
