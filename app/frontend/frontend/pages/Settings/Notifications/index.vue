<template>
  <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ t("headlines.settings.notifications") }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="saleNotify"
            :name="t('labels.user.saleNotify')"
            :slim="true"
          >
            <Checkbox
              id="saleNotify"
              v-model="form.saleNotify"
              name="saleNotify"
              :label="t('labels.user.saleNotify')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>
        </div>
      </div>
      <br />
      <Btn :loading="submitting" type="submit" size="large">
        {{ t("actions.save") }}
      </Btn>
    </form>
  </ValidationObserver>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import Checkbox from "@/shared/components/Form/Checkbox/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useSessionStore } from "@/frontend/stores/session";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();
const { displaySuccess } = useNoty();

const sessionStore = useSessionStore();

const form = ref<NotificationSettingsForm>({});

const submitting = ref(false);

onMounted(() => {
  if (sessionStore.currentUser) {
    setupForm();
  }
});

watch(
  () => sessionStore.currentUser,
  () => {
    setupForm();
  },
);

const setupForm = () => {
  form.value = {
    saleNotify: sessionStore.currentUser?.saleNotify,
  };
};

const comlink = useComlink();

const submit = async () => {
  submitting.value = true;

  const response = await userCollection.updateAccount(form.value);

  submitting.value = false;

  if (!response.error) {
    comlink.emit("user-update");

    displaySuccess({
      text: t("messages.updateNotifications.success"),
    });
  }
};
</script>

<script lang="ts">
export default {
  name: "SettingsNotificationsPage",
};
</script>
