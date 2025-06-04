<script lang="ts">
export default {
  name: "SignupPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { transformErrors } from "@/frontend/api/helpers";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useFleetStore } from "@/frontend/stores/fleet";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import {
  useSignup as useSignupMutation,
  type UserCreateInput,
  type ValidationError,
} from "@/services/fyApi";
import { useRedirectBack } from "@/shared/composables/useRedirectBack";
import Btn from "@/shared/components/base/Btn/index.vue";
import SocialLogins from "@/shared/components/SocialLogins/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { type AxiosError } from "axios";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const fleetStore = useFleetStore();

const loginRoute = computed(() => {
  return {
    name: "login",
  };
});

const initialValues = ref<UserCreateInput>({
  username: "",
  email: "",
  password: "",
  passwordConfirmation: "",
  fleetInviteToken: fleetStore.inviteToken,
  saleNotify: false,
});

const validationSchema = {
  username: "required|alpha_dash|usernameTaken",
  email: "required|email|emailTaken",
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:password",
};

const { defineField, handleSubmit, setErrors } = useForm<UserCreateInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [username, usernameProps] = defineField("username");
const [email, emailProps] = defineField("email");
const [password, passwordProps] = defineField("password");
const [passwordConfirmation, passwordConfirmationProps] = defineField(
  "passwordConfirmation",
);
const [fleetInviteToken, fleetInviteTokenProps] =
  defineField("fleetInviteToken");
const [saleNotify, saleNotifyProps] = defineField("saleNotify");

const submitting = ref(false);

const resetFleetInviteToken = () => {
  fleetStore.resetInviteToken();
};

const signupMutation = useSignupMutation();

const { handleRedirect } = useRedirectBack();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await signupMutation
    .mutateAsync({
      data: values,
    })
    .then(async () => {
      displaySuccess({
        text: t("messages.signup.success"),
      });

      fleetStore.resetInviteToken();

      handleRedirect();
    })
    .catch((error) => {
      const response = (error as AxiosError<ValidationError>).response;

      if (response?.data?.errors) {
        setErrors(transformErrors(response.data.errors));

        displayAlert({
          text: response?.data?.message,
        });
      } else {
        displayAlert({
          text: response?.data?.message,
        });
      }
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
          <router-link to="/" :exact="true">
            {{ t("title.default") }}
          </router-link>
        </h1>

        <FormInput
          v-model="username"
          v-bind="usernameProps"
          name="username"
          :hide-label-on-empty="true"
          :autofocus="true"
          debounce
        />

        <FormInput
          v-model="email"
          v-bind="emailProps"
          name="email"
          :type="InputTypesEnum.EMAIL"
          :hide-label-on-empty="true"
          debounce
        />

        <FormInput
          v-model="password"
          v-bind="passwordProps"
          name="password"
          :type="InputTypesEnum.PASSWORD"
          :hide-label-on-empty="true"
        />

        <FormInput
          v-model="passwordConfirmation"
          v-bind="passwordConfirmationProps"
          name="passwordConfirmation"
          :type="InputTypesEnum.PASSWORD"
          :hide-label-on-empty="true"
        />

        <FormInput
          v-if="fleetStore.inviteToken"
          v-model="fleetInviteToken"
          v-bind="fleetInviteTokenProps"
          name="fleetInviteToken"
          :disabled="true"
          :hide-label-on-empty="true"
          :clearable="true"
          @clear="resetFleetInviteToken"
        />

        <FormCheckbox
          v-model="saleNotify"
          v-bind="saleNotifyProps"
          name="saleNotify"
          :label="t('labels.user.saleNotify')"
        />

        <Btn
          :loading="submitting"
          :type="BtnTypesEnum.SUBMIT"
          data-test="submit-signup"
          :size="BtnSizesEnum.LARGE"
          :block="true"
        >
          {{ t("actions.signUp") }}
        </Btn>

        <hr />

        <SocialLogins only-icons />

        <hr />

        <p class="privacy-info">
          {{ t("labels.signup.privacyPolicy") }}
          <router-link :to="{ name: 'privacy-policy' }">
            {{ t("labels.privacyPolicy") }}
          </router-link>
        </p>

        <footer>
          <p class="text-center">
            {{ t("labels.alreadyRegistered") }}
          </p>

          <Btn :to="loginRoute" :size="BtnSizesEnum.SMALL" :block="true">
            {{ t("actions.login") }}
          </Btn>
        </footer>
      </form>
    </div>
  </div>
</template>

<style lang="scss">
@import "signup";
</style>
