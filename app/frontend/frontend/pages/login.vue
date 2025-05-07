<script lang="ts">
export default {
  name: "LoginPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import {
  useCreateSession as useCreateSessionMutation,
  type SessionInput,
  type ValidationError,
} from "@/services/fyApi";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import {
  BtnTypesEnum,
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { type AxiosError } from "axios";
import { useRedirectBack } from "@/shared/composables/useRedirectBack";

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const submitting = ref(false);

const twoFactorRequired = ref(false);

const initialValues = ref<SessionInput>({
  login: "",
  password: "",
  rememberMe: false,
  twoFactorCode: undefined,
});

const validationSchema = {
  login: "required",
  password: "required|min:8",
  twoFactorCode: twoFactorRequired.value ? "required" : undefined,
};

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [login, loginProps] = defineField("login");
const [password, passwordProps] = defineField("password");
const [twoFactorCode, twoFactorCodeProps] = defineField("twoFactorCode");
const [rememberMe, rememberMeProps] = defineField("rememberMe");

const sessionStore = useSessionStore();

const mutation = useCreateSessionMutation();

const { handleRedirect } = useRedirectBack();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
    })
    .then(async () => {
      sessionStore.login();

      handleRedirect();
    })
    .catch((error) => {
      const response = (error as AxiosError).response;

      if (response) {
        const data = response.data as ValidationError;
        if (data.code === "session.create.two_factor_required") {
          twoFactorRequired.value = true;
        } else {
          displayAlert({
            text: data.message || t("errors.generic"),
          });
        }
      } else {
        displayAlert({
          text: t("errors.generic"),
        });
      }
    })
    .finally(() => {
      submitting.value = false;
    });
});

const signupRoute = computed(() => {
  return {
    name: "signup",
  };
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

        <template v-if="twoFactorRequired">
          <FormInput
            v-model="twoFactorCode"
            v-bind="twoFactorCodeProps"
            name="twoFactorCode"
            :autofocus="true"
            :hide-label-on-empty="true"
            :clearable="true"
          />
        </template>
        <div v-show="!twoFactorRequired">
          <FormInput
            v-model="login"
            v-bind="loginProps"
            name="login"
            :autofocus="true"
            :hide-label-on-empty="true"
            :clearable="true"
          />
          <FormInput
            v-model="password"
            v-bind="passwordProps"
            name="password"
            :type="InputTypesEnum.PASSWORD"
            :hide-label-on-empty="true"
            :clearable="true"
          />
          <FormCheckbox
            v-model="rememberMe"
            v-bind="rememberMeProps"
            name="rememberMe"
            :label="t('labels.rememberMe')"
          />
        </div>
        <Btn
          :loading="submitting"
          :type="BtnTypesEnum.SUBMIT"
          data-test="submit-login"
          :size="BtnSizesEnum.LARGE"
          :block="true"
        >
          {{ t("actions.login") }}
        </Btn>
        <Btn
          :to="{
            name: 'request-password',
          }"
          :variant="BtnVariantsEnum.LINK"
          :size="BtnSizesEnum.SMALL"
          :block="true"
        >
          {{ t("actions.reset-password") }}
        </Btn>
        <footer>
          <p class="text-center">
            {{ t("labels.signup.link") }}
          </p>
          <Btn
            data-test="signup-link"
            :to="signupRoute"
            :size="BtnSizesEnum.SMALL"
            :block="true"
          >
            {{ t("actions.signUp") }}
          </Btn>
        </footer>
      </form>
    </div>
  </div>
</template>

<style lang="scss">
@import "login";
</style>
