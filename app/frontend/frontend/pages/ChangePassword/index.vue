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
import Btn from "@/shared/components/BaseBtn/index.vue";
import FormInput from "@/shared/components/Form/FormInput/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useRouter, useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty(t);

type ChangePasswordForm = {
  currentPassword: string;
  password: string;
  passwordConfirmation: string;
};

const form = ref<Partial<ChangePasswordForm>>({});

const submitting = ref(false);

const { isAuthenticated } = storeToRefs(useSessionStore());

const router = useRouter();

onMounted(() => {
  if (isAuthenticated.value) {
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push({ name: "settings-change-password" }).catch(() => {});
  }
});

const route = useRoute();

const changePassword = async () => {
  submitting.value = true;

  const response = await this.$api.put(
    `password/update/${route.params.token}`,
    form.value
  );

  submitting.value = false;

  if (!response.error) {
    displaySuccess({
      text: t("messages.changePassword.success"),
    });

    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push("/").catch(() => {});
  } else {
    displayAlert({
      text: t("messages.changePassword.failure"),
    });
  }
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
