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
                id="email"
                v-model="form.email"
                :error="errors[0]"
                type="email"
                :hide-label-on-empty="true"
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
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Store from "@/frontend/lib/Store";

import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type { PasswordRequestInput } from "@/services/fyApi";
import { useRouter } from "vue-router/composables";

const { t } = useI18n();

const submitting = ref(false);

const form = ref<PasswordRequestInput>({});

const isAuthenticated = computed(
  () => Store.getters["session/isAuthenticated"]
);

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

    displaySuccess({
      text: t("messages.requestPasswordChange.success"),
    });

    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push("/").catch(() => {});
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.requestPasswordChange.failure"),
    });
  }

  submitting.value = false;
};
</script>

<script lang="ts">
export default {
  name: "RequestPasswordPage",
};
</script>

<style lang="scss">
@import "index";
</style>
