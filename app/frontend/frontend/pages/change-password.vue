<script lang="ts">
export default {
  name: "ChangePasswordPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type PasswordInput } from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useUpdatePasswordWithToken as useUpdatePasswordWithTokenMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const router = useRouter();

const validationSchema = {
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:password",
};

const { defineField, handleSubmit } = useForm<PasswordInput>({
  validationSchema,
});

const [password, passwordProps] = defineField("password");
const [passwordConfirmation, passwordConfirmationProps] = defineField(
  "passwordConfirmation",
);

onMounted(() => {
  if (isAuthenticated.value) {
    router.push({ name: "settings-change-password" });
  }
});

const route = useRoute();

const mutation = useUpdatePasswordWithTokenMutation();

const onSubmit = handleSubmit(async (values) => {
  if (!route.params.token) {
    displayAlert({
      text: t("messages.changePassword.failure"),
    });
  }

  submitting.value = true;

  await mutation
    .mutateAsync({
      token: String(route.params.token),
      data: values,
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
  <div class="row">
    <div class="col-12">
      <form @submit.prevent="onSubmit">
        <h1>
          <router-link :to="{ name: 'home' }" exact>
            {{ t("title.default") }}
          </router-link>
        </h1>
        <FormInput
          v-model="password"
          name="password"
          :label="t('labels.password')"
          :type="InputTypesEnum.PASSWORD"
          :autofocus="true"
          v-bind="passwordProps"
          :hide-label-on-empty="true"
        />

        <FormInput
          v-model="passwordConfirmation"
          name="passwordConfirmation"
          :label="t('labels.passwordConfirmation')"
          v-bind="passwordConfirmationProps"
          :type="InputTypesEnum.PASSWORD"
          :hide-label-on-empty="true"
        />

        <Btn
          :loading="submitting"
          :type="BtnTypesEnum.SUBMIT"
          :size="BtnSizesEnum.LARGE"
          :block="true"
        >
          {{ t("actions.save") }}
        </Btn>

        <footer>
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
@import "change-password";
</style>
