<template>
  <section class="container signup">
    <div class="row">
      <div v-if="signupForm" class="col-12">
        <ValidationObserver ref="form" v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(signup)">
            <h1>
              <router-link to="/" :exact="true">
                {{ $t("app") }}
              </router-link>
            </h1>
            <ValidationProvider
              v-slot="{ errors }"
              vid="username"
              rules="required|alpha_dash|usernameTaken"
              :name="$t('labels.username')"
              :slim="true"
            >
              <FormInput
                id="username"
                v-model="signupForm.username"
                :error="errors[0]"
                :hide-label-on-empty="true"
                :autofocus="true"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="email"
              rules="required|email"
              :name="$t('labels.email')"
              :slim="true"
            >
              <FormInput
                id="email"
                v-model="signupForm.email"
                :error="errors[0]"
                :hide-label-on-empty="true"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="password"
              rules="required|min:8"
              :name="$t('labels.password')"
              :slim="true"
            >
              <FormInput
                id="password"
                v-model="signupForm.password"
                :error="errors[0]"
                type="password"
                :hide-label-on-empty="true"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="passwordConfirmation"
              rules="required|confirmed:password"
              :name="$t('labels.passwordConfirmation')"
              :slim="true"
            >
              <FormInput
                id="passwordConfirmation"
                v-model="signupForm.passwordConfirmation"
                :error="errors[0]"
                type="password"
                :hide-label-on-empty="true"
              />
            </ValidationProvider>

            <FormInput
              v-if="inviteToken"
              id="fleetInviteToken"
              v-model="signupForm.fleetInviteToken"
              :disabled="true"
              :hide-label-on-empty="true"
              :clearable="true"
              @clear="resetFleetInviteToken"
            />

            <Checkbox
              id="saleNotify"
              v-model="signupForm.saleNotify"
              :label="$t('labels.user.saleNotify')"
            />

            <Btn
              :loading="submitting"
              type="submit"
              data-test="submit-signup"
              size="large"
              :block="true"
            >
              {{ $t("actions.signUp") }}
            </Btn>

            <p class="privacy-info">
              {{ $t("labels.signup.privacyPolicy") }}
              <router-link :to="{ name: 'privacy-policy' }">
                {{ $t("labels.privacyPolicy") }}
              </router-link>
            </p>

            <footer>
              <p class="text-center">
                {{ $t("labels.alreadyRegistered") }}
              </p>

              <Btn :to="{ name: 'login' }" size="small" :block="true">
                {{ $t("actions.login") }}
              </Btn>
            </footer>
          </form>
        </ValidationObserver>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import { useFleetStore } from "@/frontend/stores/Fleet";
import { ValidationObserver } from "vee-validate";
import { useI18n } from "@/frontend/composables/useI18n";
import userCollection from "@/frontend/api/collections/User";
import { storeToRefs } from "pinia";

const fleetStore = useFleetStore();

const { inviteToken } = storeToRefs(fleetStore);

const signupForm = ref<Partial<TSignupForm> | null>(null);

const submitting = ref(false);

const setupForm = () => {
  signupForm.value = {
    username: undefined,
    email: undefined,
    saleNotify: false,
    password: undefined,
    passwordConfirmation: undefined,
    fleetInviteToken: inviteToken?.value,
  };
};

onMounted(() => {
  setupForm();
});

const router = useRouter();

const form = ref<InstanceType<typeof ValidationObserver> | null>(null);

const { t } = useI18n();

const signup = async () => {
  submitting.value = true;

  const response = await userCollection.signup(signupForm.value as TSignupForm);

  submitting.value = false;

  if (userCollection.isErrorResponse(response)) {
    const errorCode = response.error;
    if (errorCode === "blocked") {
      displayAlert({
        text: t("texts.signup.blocked"),
      });

      return;
    }

    const { errors } = response;

    if (errors) {
      form.value?.setErrors(errors);

      displayAlert({
        text: response.message,
      });
    } else {
      displayAlert({
        text: t("messages.signup.failure"),
      });
    }
  } else {
    displaySuccess({
      text: t("messages.signup.success"),
    });

    fleetStore.resetInviteToken();

    router.push("/").catch(() => {
      // ignore
    });
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
