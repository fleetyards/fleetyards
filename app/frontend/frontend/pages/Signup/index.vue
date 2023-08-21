<template>
  <section class="container signup">
    <div class="row">
      <div v-if="form" class="col-12">
        <ValidationObserver ref="form" v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(signup)">
            <h1>
              <router-link to="/" :exact="true">
                {{ t("app") }}
              </router-link>
            </h1>
            <ValidationProvider
              v-slot="{ errors }"
              vid="username"
              rules="required|alpha_dash|usernameTaken"
              :name="t('labels.username')"
              :slim="true"
            >
              <FormInput
                id="username"
                v-model="form.username"
                :error="errors[0]"
                :hide-label-on-empty="true"
                :autofocus="true"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="email"
              rules="required|email"
              :name="t('labels.email')"
              :slim="true"
            >
              <FormInput
                id="email"
                v-model="form.email"
                :error="errors[0]"
                :hide-label-on-empty="true"
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
                :hide-label-on-empty="true"
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
                :hide-label-on-empty="true"
              />
            </ValidationProvider>

            <FormInput
              v-if="fleetInviteToken"
              id="fleetInviteToken"
              v-model="form.fleetInviteToken"
              :disabled="true"
              :hide-label-on-empty="true"
              :clearable="true"
              @clear="resetFleetInviteToken"
            />

            <Checkbox
              name="saleNotify"
              id="saleNotify"
              v-model="form.saleNotify"
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
        </ValidationObserver>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/Btn/index.vue";
import { transformErrors } from "@/frontend/api/helpers";
import FormInput from "@/shared/components/Form/FormInput/index.vue";
import Checkbox from "@/shared/components/Form/Checkbox/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useFleetStore } from "@/frontend/stores/fleet";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty(t);

const fleetStore = useFleetStore();

const { inviteToken: fleetInviteToken } = storeToRefs(fleetStore);

const form = ref<SignupForm>({});

const submitting = ref(false);

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    username: null,
    email: null,
    saleNotify: false,
    password: null,
    passwordConfirmation: null,
    fleetInviteToken: fleetStore.inviteToken,
  };
};

const resetFleetInviteToken = () => {};

const router = useRouter();

const signup = async () => {
  submitting.value = true;

  const response = await this.$api.post("users/signup", this.form);

  submitting.value = false;

  if (!response.error) {
    displaySuccess({
      text: t("messages.signup.success"),
    });

    fleetStore.resetInviteToken();

    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push("/").catch(() => {});
  } else if (
    response.error.response &&
    response.error.response.data &&
    response.error.response.data.code === "blocked"
  ) {
    displayAlert({
      text: t("texts.signup.blocked"),
    });
  } else {
    const { error } = response;
    if (error.response && error.response.data) {
      const { data: errorData } = error.response;

      this.$refs.form.setErrors(transformErrors(errorData.errors));

      displayAlert({
        text: errorData.message,
      });
    } else {
      displayAlert({
        text: t("messages.signup.failure"),
      });
    }
  }
};
</script>

<script lang="ts">
export default {
  name: "SignupPage",
};
</script>

<style lang="scss">
@import "index";
</style>
