<script lang="ts">
export default {
  name: "SignupPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { transformErrors } from "@/frontend/api/helpers";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useFleetStore } from "@/frontend/stores/fleet";
import { storeToRefs } from "pinia";
import type {
  UserCreateInput,
  ApiError,
  ValidationError,
} from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty();

const fleetStore = useFleetStore();

const { inviteToken: fleetInviteToken } = storeToRefs(fleetStore);

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
  email: "required|email",
  password: "required|min:8",
  passwordConfirmation: "required|confirmed:password",
};

const { values, handleSubmit, setErrors } = useForm({
  initialValues,
  validationSchema,
});

const submitting = ref(false);

const resetFleetInviteToken = () => {};

const router = useRouter();

const { users: usersService } = useApiClient();

const onSubmit = handleSubmit(async (values: UserCreateInput) => {
  submitting.value = true;

  try {
    await usersService.signup({
      requestBody: values,
    });

    displaySuccess({
      text: t("messages.signup.success"),
    });

    fleetStore.resetInviteToken();

    router.push("/").catch(() => {});
  } catch (error) {
    const errorResponse = (error as ApiError).body as ValidationError;

    if (errorResponse.errors) {
      setErrors(transformErrors(errorResponse.errors));

      displayAlert({
        text: errorResponse.message,
      });
    } else {
      displayAlert({
        text: errorResponse.message,
      });
    }
  }

  submitting.value = false;
});
</script>

<template>
  <div class="row">
    <div class="col-12">
      <form @submit="onSubmit">
        <h1>
          <router-link to="/" :exact="true">
            {{ t("app") }}
          </router-link>
        </h1>

        <FormInput
          v-model="values.username"
          name="username"
          :hide-label-on-empty="true"
          :autofocus="true"
        />

        <FormInput
          v-model="values.email"
          name="email"
          :hide-label-on-empty="true"
        />

        <FormInput
          v-model="values.password"
          name="password"
          type="password"
          :hide-label-on-empty="true"
        />

        <FormInput
          v-model="values.passwordConfirmation"
          name="passwordConfirmation"
          type="password"
          :hide-label-on-empty="true"
        />

        <FormInput
          v-if="fleetInviteToken"
          v-model="values.fleetInviteToken"
          name="fleetInviteToken"
          :disabled="true"
          :hide-label-on-empty="true"
          :clearable="true"
          @clear="resetFleetInviteToken"
        />

        <Checkbox
          v-model="values.saleNotify"
          name="saleNotify"
          :label="t('labels.user.saleNotify')"
        />

        <Btn
          :loading="submitting"
          type="submit"
          data-test="submit-signup"
          size="large"
          :block="true"
        >
          {{ t("actions.signUp") }}
        </Btn>

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

          <Btn :to="{ name: 'login' }" size="small" :block="true">
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
