<template>
  <section class="container login">
    <div class="row">
      <div v-if="form" class="col-12">
        <ValidationObserver ref="form" v-slot="{ handleSubmit }" :small="true">
          <form @submit.prevent="handleSubmit(login)">
            <h1>
              <router-link to="/" exact>
                {{ t("app") }}
              </router-link>
            </h1>
            <template v-if="twoFactorRequired">
              <ValidationProvider
                v-slot="{ errors }"
                vid="twoFactorCode"
                rules="required"
                :name="t('labels.twoFactorCode')"
                :slim="true"
              >
                <FormInput
                  id="twoFactorCode"
                  v-model="form.twoFactorCode"
                  :error="errors[0]"
                  :autofocus="true"
                  :hide-label-on-empty="true"
                  :clearable="true"
                />
              </ValidationProvider>
            </template>
            <div v-show="!twoFactorRequired">
              <ValidationProvider
                v-slot="{ errors }"
                vid="login"
                rules="required"
                :name="t('labels.login')"
                :slim="true"
              >
                <FormInput
                  id="login"
                  v-model="form.login"
                  :error="errors[0]"
                  :autofocus="true"
                  :hide-label-on-empty="true"
                  :clearable="true"
                />
              </ValidationProvider>

              <ValidationProvider
                v-slot="{ errors }"
                vid="password"
                rules="required"
                :name="t('labels.password')"
                :slim="true"
              >
                <FormInput
                  id="password"
                  v-model="form.password"
                  :error="errors[0]"
                  type="password"
                  :hide-label-on-empty="true"
                  :clearable="true"
                />
              </ValidationProvider>
              <Checkbox
                id="rememberMe"
                v-model="form.rememberMe"
                :label="t('labels.rememberMe')"
              />
            </div>
            <Btn
              :loading="submitting"
              type="submit"
              data-test="submit-login"
              size="large"
              :block="true"
            >
              {{ t("actions.login") }}
            </Btn>
            <Btn
              :to="{
                name: 'request-password',
              }"
              variant="link"
              size="small"
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
                :to="{ name: 'signup' }"
                size="small"
                :block="true"
              >
                {{ t("actions.signUp") }}
              </Btn>
            </footer>
          </form>
        </ValidationObserver>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/frontend/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import type { RouteParamsRaw, LocationQueryRaw } from "vue-router";

const { t } = useI18n();

const { displayAlert } = useNoty(t);

const submitting = ref(false);

const twoFactorRequired = ref(false);

const form = ref<LoginForm>({});

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    rememberMe: false,
    password: null,
    login: null,
    twoFactorCode: null,
  };
};

const sessionStore = useSessionStore();

const route = useRoute();
const router = useRouter();

const login = async () => {
  submitting.value = true;

  const response = await sessionCollection.create(form.value);

  submitting.value = false;

  if (
    response.error &&
    response.error.response?.data?.code === "session.create.two_factor_required"
  ) {
    twoFactorRequired.value = true;
  } else if (!response.error) {
    sessionStore.login();

    if (route.params.redirectToRoute) {
      await router.replace({
        name: route.params.redirectToRoute as string,
        params: route.params.redirectToRouteParams as unknown as RouteParamsRaw,
        query: route.params.redirectToRouteQuery as unknown as LocationQueryRaw,
      });
    } else {
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      await router.push("/").catch(() => {});
    }
  } else {
    displayAlert({
      text: response.error.response.data.message,
    });
  }
};
</script>

<script lang="ts">
export default {
  name: "LoginPage",
};
</script>

<style lang="scss">
@import "index";
</style>
