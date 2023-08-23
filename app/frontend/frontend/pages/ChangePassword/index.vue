<template>
  <section class="container change-password">
    <div class="row">
      <div class="col-12">
        <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(changePassword)">
            <h1>
              <router-link :to="{ name: 'home' }" exact>
                {{ t("app") }}
              </router-link>
            </h1>
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
                :autofocus="true"
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

            <Btn :loading="submitting" type="submit" size="large" :block="true">
              {{ t("actions.save") }}
            </Btn>

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
import Btn from "@/frontend/core/components/Btn/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type { PasswordInput } from "@/services/fyApi";
import { useNoty } from "@/shared/composables/useNoty";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty(t);

const submitting = ref(false);

const form = ref<PasswordInput>({});

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const router = useRouter();

onMounted(() => {
  if (isAuthenticated.value) {
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push({ name: "settings-change-password" }).catch(() => {});
  }
});

const route = useRoute();

const { password: passwordService } = useApiClient();

const changePassword = async () => {
  if (!route.params.token) {
    displayAlert({
      text: t("messages.changePassword.failure"),
    });
  }

  submitting.value = true;

  try {
    await passwordService.updatePasswordWithToken({
      token: String(route.params.token),
      requestBody: form.value,
    });

    displaySuccess({
      text: t("messages.changePassword.success"),
    });

    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push("/").catch(() => {});
  } catch (error) {
    console.error(error);
    displayAlert({
      text: t("messages.changePassword.failure"),
    });
  }

  submitting.value = false;
};
</script>

<script lang="ts">
export default {
  name: "ChangePasswordPage",
};
</script>

<style lang="scss">
@import "index";
</style>
