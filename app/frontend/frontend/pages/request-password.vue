<template>
  <section class="container request-password">
    <div class="row">
      <div class="col-12">
        <ValidationObserver v-if="form" v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(requestPassword)">
            <h1>
              <router-link to="/" exact>
                {{ t("app") }}
              </router-link>
            </h1>

            <ValidationProvider
              v-slot="{ errors }"
              vid="email"
              rules="required|email"
              :name="t('labels.email')"
              :slim="true"
            >
              <FormInput
                v-model="form.email"
                name="email"
                :error="errors[0]"
                type="email"
                :hide-label-on-empty="true"
                autocomplete="off"
                :autofocus="true"
              />
            </ValidationProvider>

            <Btn :loading="submitting" type="submit" size="large" :block="true">
              {{ t("actions.requestPassword") }}
            </Btn>

            <footer v-if="!isAuthenticated">
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
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type { PasswordRequestInput } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const { displaySuccess } = useNoty(t);

const submitting = ref(false);

const form = ref<PasswordRequestInput>({});

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    email: undefined,
  };
};

const { password: passwordService } = useApiClient();

const router = useRouter();

const requestPassword = async () => {
  submitting.value = true;

  try {
    await passwordService.requestPasswordReset({
      requestBody: form.value,
    });
  } catch (error) {
    // console.error(error);
  }

  displaySuccess({
    text: t("messages.requestPasswordChange.success"),
  });

  submitting.value = false;

  // eslint-disable-next-line @typescript-eslint/no-empty-function
  router.push("/").catch(() => {});
};
</script>

<script lang="ts">
export default {
  name: "RequestPasswordPage",
};
</script>

<style lang="scss">
@import "request-password";
</style>
