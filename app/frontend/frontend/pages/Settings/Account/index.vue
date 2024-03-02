<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ t("headlines.settings.account") }}</h1>
        </div>
      </div>

      <div class="row">
        <div class="col-12">
          <form @submit.prevent="updateAccount">
            <div class="row">
              <div class="col-12 col-md-6">
                <FormInput v-model="username" name="username" />
                <FormInput v-model="email" name="email" type="email" />

                <FormInput
                  v-if="currentUser?.unconfirmedEmail"
                  v-model="currentUser.unconfirmedEmail"
                  name="unconfirmedEmail"
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
            @click="destroy"
          >
            {{ t("actions.destroyAccount") }}
          </Btn>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useRouter } from "vue-router";
import { useNoty } from "@/shared/composables/useNoty";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useForm } from "vee-validate";

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

type UserUpdateInput = {
  username?: string;
  email?: string;
};

const initialValues = ref<UserUpdateInput>({
  username: sessionStore.currentUser?.username,
  email: sessionStore.currentUser?.email,
});

const deleting = ref(false);

const submitting = ref(false);

const { useFieldModel, handleSubmit } = useForm({ initialValues });

const [username, email] = useFieldModel(["username", "email"]);

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
  initialValues.value = {
    username: sessionStore.currentUser?.username,
    email: sessionStore.currentUser?.email,
  };
};

const comlink = useComlink();

const { t } = useI18n();

const { displaySuccess, displayAlert, displayConfirm } = useNoty(t);

const updateAccount = handleSubmit(async () => {
  if (!initialValues.value) {
    return;
  }

  submitting.value = true;

  // const response = await userCollection.updateAccount(form.value);

  submitting.value = false;

  // if (!response.error) {
  //   comlink.emit("user-update");

  //   displaySuccess({
  //     text: t("messages.updateAccount.success"),
  //   });
  // }
});

const router = useRouter();

const destroy = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.account.destroy"),
    onConfirm: async () => {
      // const response = await userCollection.destroy();

      deleting.value = false;

      // if (!response.error) {
      //   displaySuccess({
      //     text: t("messages.account.destroy.success"),
      //   });

      //   sessionStore.logout();

      //   // eslint-disable-next-line @typescript-eslint/no-empty-function
      //   router.push({ name: "home" }).catch(() => {});
      // } else {
      //   displayAlert({
      //     text: t("messages.account.destroy.error"),
      //   });
      // }
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
