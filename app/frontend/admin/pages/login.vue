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
import Heading from "@/shared/components/base/Heading/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/admin/stores/session";
import {
  useCreateSession as useCreateSessionMutation,
  type ValidationError,
  type SessionInput,
} from "@/services/fyAdminApi";
import { type ErrorType } from "@/services/fyAdminApi/axiosClient";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { BtnTypesEnum, BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  HeadingLevelEnum,
  HeadingAlignmentEnum,
} from "@/shared/components/base/Heading/types";
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
      const response = error as unknown as ErrorType<ValidationError>;

      if (response?.code === "session.create.two_factor_required") {
        twoFactorRequired.value = true;
      } else {
        displayAlert({
          text: response.response?.data?.message || t("errors.generic"),
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
        <Heading
          :level="HeadingLevelEnum.H1"
          :alignment="HeadingAlignmentEnum.CENTER"
        >
          <router-link to="/" exact>
            {{ t("title.defaultAdmin") }}
          </router-link>
        </Heading>

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
      </form>
    </div>
  </div>
</template>

<style lang="scss">
@import "login";
</style>
