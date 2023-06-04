<template>
  <SecurePage class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ t("headlines.settings.account") }}</h1>
        </div>
      </div>

      <div class="row">
        <div class="col-12">
          <ValidationObserver
            v-if="form"
            v-slot="{ handleSubmit }"
            :slim="true"
          >
            <form @submit.prevent="handleSubmit(updateAccount)">
              <div class="row">
                <div class="col-12 col-md-6">
                  <ValidationProvider
                    v-slot="{ errors }"
                    vid="username"
                    rules="required|alpha_dash"
                    :name="t('labels.username')"
                    :slim="true"
                  >
                    <FormInput
                      id="username"
                      v-model="form.username"
                      :error="errors[0]"
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
                      type="email"
                    />
                  </ValidationProvider>

                  <FormInput
                    v-if="currentUser.unconfirmedEmail"
                    id="unconfirmedEmail"
                    v-model="currentUser.unconfirmedEmail"
                    type="email"
                    :disabled="true"
                    :label="t('labels.user.unconfirmedEmail')"
                    :no-placeholder="true"
                  />
                  <Btn :loading="submitting" type="submit" size="large">
                    {{ t("actions.save") }}
                  </Btn>
                </div>
              </div>
            </form>
          </ValidationObserver>
        </div>
      </div>

      <hr />

      <div class="row">
        <div class="col-12">
          <br />
          <p>
            {{ t("labels.account.destroyInfo") }}
          </p>
          <Btn
            :loading="deleting"
            variant="danger"
            size="large"
            data-test="destroy-account"
            @click.native="destroy"
          >
            {{ t("actions.destroyAccount") }}
          </Btn>
        </div>
      </div>
    </div>
  </SecurePage>
</template>

<script lang="ts" setup>
import { useRouter } from "vue-router/composables";
import {
  displaySuccess,
  displayAlert,
  displayConfirm,
} from "@/frontend/lib/Noty";
import Btn from "@/frontend/core/components/Btn/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import userCollection from "@/frontend/api/collections/User";
import SecurePage from "@/frontend/core/components/SecurePage/index.vue";
import { useComlink } from "@/frontend/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";

const currentUser = computed(() => Store.getters["session/currentUser"]);

const form = ref<UserAccountForm | null>(null);

const deleting = ref(false);

const submitting = ref(false);

onMounted(() => {
  if (currentUser.value) {
    setupForm();
  }
});

watch(
  () => currentUser.value,
  () => {
    setupForm();
  }
);

const setupForm = () => {
  form.value = {
    username: currentUser.value.username,
    email: currentUser.value.email,
  };
};

const comlink = useComlink();

const { t } = useI18n();

const updateAccount = async () => {
  if (!form.value) {
    return;
  }

  submitting.value = true;

  const response = await userCollection.updateAccount(form.value);

  submitting.value = false;

  if (!response.error) {
    comlink.$emit("user-update");

    displaySuccess({
      text: t("messages.updateAccount.success"),
    });
  }
};

const router = useRouter();

const destroy = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.account.destroy"),
    onConfirm: async () => {
      const response = await userCollection.destroy();

      deleting.value = false;

      if (!response.error) {
        displaySuccess({
          text: t("messages.account.destroy.success"),
        });

        await Store.dispatch("session/logout");

        // eslint-disable-next-line @typescript-eslint/no-empty-function
        router.push({ name: "home" }).catch(() => {});
      } else {
        displayAlert({
          text: t("messages.account.destroy.error"),
        });
      }
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "SettingsAccount",
};
</script>
