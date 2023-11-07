<template>
  <section class="container login">
    <div class="row">
      <div class="col-12">
        <form method="post" @submit="onSubmit">
          <h1>
            <router-link to="/" exact>
              {{ t("app") }}
            </router-link>
          </h1>

          <template v-if="twoFactorRequired">
            <FormInput
              v-model="values.twoFactorCode"
              name="twoFactorCode"
              :autofocus="true"
              :hide-label-on-empty="true"
              :clearable="true"
            />
          </template>
          <div v-show="!twoFactorRequired">
            <FormInput
              v-model="values.login"
              name="login"
              :autofocus="true"
              :hide-label-on-empty="true"
              :clearable="true"
            />
            <FormInput
              v-model="values.password"
              name="password"
              type="password"
              :hide-label-on-empty="true"
              :clearable="true"
            />
            <Checkbox
              v-model="values.rememberMe"
              name="rememberMe"
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
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Checkbox from "@/shared/components/base/Checkbox/index.vue";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/frontend/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import type { RouteParamsRaw, LocationQueryRaw } from "vue-router";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { SessionInput, ApiError } from "@/services/fyApi";

const { t } = useI18n();

const { displayAlert } = useNoty(t);

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

const { values, handleSubmit } = useForm({
  initialValues,
  validationSchema,
});

const sessionStore = useSessionStore();

const route = useRoute();
const router = useRouter();

const { sessions: sessionsService } = useApiClient();

onMounted(() => {
  if (sessionStore.isAuthenticated) {
    router.push({ name: "hangar" }).catch(() => {});
  }
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await sessionsService.createSession({
      requestBody: values,
    });

    sessionStore.login();

    if (route.params.redirectToRoute) {
      await router.replace({
        name: route.params.redirectToRoute as string,
        params: route.params.redirectToRouteParams as unknown as RouteParamsRaw,
        query: route.params.redirectToRouteQuery as unknown as LocationQueryRaw,
      });
    } else {
      await router.push("/").catch(() => {});
    }
  } catch (error) {
    const body = (error as unknown as ApiError).body;

    if (body.code === "session.create.two_factor_required") {
      twoFactorRequired.value = true;
    } else {
      displayAlert({
        text: body.message,
      });
    }
  }

  submitting.value = false;
});
</script>

<script lang="ts">
export default {
  name: "LoginPage",
};
</script>

<style lang="scss">
@import "index";
</style>
