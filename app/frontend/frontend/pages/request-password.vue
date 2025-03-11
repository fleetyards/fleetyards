<script lang="ts">
export default {
  name: "RequestPasswordPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import type { PasswordRequestInput } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { useForm } from "vee-validate";
import { useRequestPasswordReset as useRequestPasswordResetMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess } = useAppNotifications();

const submitting = ref(false);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const { defineField, handleSubmit } = useForm<PasswordRequestInput>({
  validationSchema: {
    email: "required|email",
  },
});

const [email, emailProps] = defineField("email");

const router = useRouter();

const mutation = useRequestPasswordResetMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
    })
    .then(async () => {
      displaySuccess({
        text: t("messages.requestPasswordChange.success"),
      });

      await router.push("/").catch(() => {});
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
  <div class="row">
    <div class="col-12">
      <form @submit.prevent="onSubmit">
        <h1>
          <router-link to="/" exact>
            {{ t("title.default") }}
          </router-link>
        </h1>

        <FormInput
          v-model="email"
          name="email"
          :label="t('labels.email')"
          :type="InputTypesEnum.EMAIL"
          :hide-label-on-empty="true"
          autocomplete="off"
          v-bind="emailProps"
          :autofocus="true"
        />
        <Btn
          :loading="submitting"
          :type="BtnTypesEnum.SUBMIT"
          :size="BtnSizesEnum.LARGE"
          :block="true"
        >
          {{ t("actions.requestPassword") }}
        </Btn>

        <footer v-if="!isAuthenticated">
          <p class="text-center">
            {{ t("labels.alreadyRegistered") }}
          </p>

          <Btn :to="{ name: 'login' }" :size="BtnSizesEnum.SMALL" :block="true">
            {{ t("actions.login") }}
          </Btn>
        </footer>
      </form>
    </div>
  </div>
</template>

<style lang="scss">
@import "request-password";
</style>
