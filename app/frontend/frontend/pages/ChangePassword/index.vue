<template>
  <section class="container change-password">
    <div class="row">
      <div class="col-12">
        <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(changePassword)">
            <h1>
              <router-link :to="{ name: 'home' }" exact>
                {{ $t("app") }}
              </router-link>
            </h1>
            <ValidationProvider
              v-slot="{ errors }"
              vid="password"
              rules="required|min:8"
              :name="$t('labels.password')"
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
              :name="$t('labels.passwordConfirmation')"
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
              {{ $t("actions.save") }}
            </Btn>

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
import { useRoute, useRouter } from "vue-router";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/Session";
import passwordCollection from "@/frontend/api/collections/Password";

const submitting = ref(false);

const form = ref<Partial<PasswordChangeForm>>({
  currentPassword: undefined,
  password: undefined,
  passwordConfirmation: undefined,
});

const router = useRouter();

const sessionStore = useSessionStore();

onMounted(() => {
  if (sessionStore.isAuthenticated) {
    router.push({ name: "settings-change-password" }).catch(() => {
      // ignore
    });
  }
});

const route = useRoute();

const { t } = useI18n();

const changePassword = async () => {
  submitting.value = true;

  const response = await passwordCollection.update(
    route.params.token,
    form.value as PasswordChangeForm
  );

  submitting.value = false;

  if (!response.error) {
    displaySuccess({
      text: t("messages.changePassword.success"),
    });

    router.push("/").catch(() => {
      // ignore
    });
  } else {
    displayAlert({
      text: t("messages.changePassword.failure"),
    });
  }
};
</script>

<script lang="ts">
export default {
  name: "ChangePassword",
};
</script>

<style lang="scss">
@import "index";
</style>
