<template>
  <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
    <form v-if="form" @submit.prevent="handleSubmit(changePassword)">
      <ValidationProvider
        v-slot="{ errors }"
        vid="currentPassword"
        rules="required"
        :name="t('labels.currentPassword')"
        :slim="true"
      >
        <FormInput
          id="currentPassword"
          v-model="form.currentPassword"
          :error="errors[0]"
          type="password"
        />
      </ValidationProvider>

      <ValidationProvider
        v-slot="{ errors }"
        vid="password"
        rules="required|min:8"
        :name="t('labels.password')"
        :slim="true"
      >
        <FormInput
          id="password"
          v-model="form.password"
          :error="errors[0]"
          type="password"
        />
      </ValidationProvider>

      <ValidationProvider
        v-slot="{ errors }"
        vid="passwordConfirmation"
        rules="required|confirmed:password"
        :name="t('labels.passwordConfirmation')"
        :slim="true"
      >
        <FormInput
          id="passwordConfirmation"
          v-model="form.passwordConfirmation"
          :error="errors[0]"
          type="password"
        />
      </ValidationProvider>
      <div class="d-flex">
        <Btn :loading="submitting" type="submit">
          {{ t("actions.updatePassword") }}
        </Btn>
        <Btn :to="{ name: 'request-password' }" variant="link">
          {{ t("actions.reset-password") }}
        </Btn>
      </div>
    </form>
  </ValidationObserver>
</template>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useRouter } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type { PasswordInput } from "@/services/fyApi";
import { useNoty } from "@/shared/composables/useNoty";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty();

const submitting = ref(false);

const form = ref<PasswordInput>({});

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    currentPassword: undefined,
    password: undefined,
    passwordConfirmation: undefined,
  };
};

const router = useRouter();

const { password: passwordService } = useApiClient();

const changePassword = async () => {
  submitting.value = true;

  try {
    await passwordService.updatePassword({
      requestBody: form.value,
    });

    displaySuccess({
      text: t("messages.changePassword.success"),
    });

    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push("/").catch(() => {});
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.changePassword.failure"),
    });
  }

  submitting.value = false;
};
</script>

<script lang="ts">
export default {
  name: "ChangePasswordForm",
};
</script>
