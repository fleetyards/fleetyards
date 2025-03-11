<script lang="ts">
export default {
  name: "SettingsAccount",
};
</script>

<script lang="ts" setup>
import { useRouter } from "vue-router";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useForm } from "vee-validate";
import { type AccountUpdateInput } from "@/services/fyApi";
import {
  BtnVariantsEnum,
  BtnSizesEnum,
  BtnTypesEnum,
} from "@/shared/components/base/Btn/types";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import {
  useUpdateAccount as useUpdateAccountMutation,
  useDestroyAccount as useDestroyAccountMutation,
} from "@/services/fyApi";

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const initialValues = ref<AccountUpdateInput>({
  username: sessionStore.currentUser?.username,
  email: sessionStore.currentUser?.email,
});

const deleting = ref(false);

const submitting = ref(false);

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [username, usernameProps] = defineField("username");
const [email, emailProps] = defineField("email");

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

const { displaySuccess, displayAlert } = useAppNotifications();

const updateMutation = useUpdateAccountMutation();

const updateAccount = handleSubmit(async (values) => {
  if (!initialValues.value) {
    return;
  }

  submitting.value = true;

  await updateMutation
    .mutateAsync({
      data: values,
    })
    .then(() => {
      comlink.emit("user-update");

      displaySuccess({
        text: t("messages.updateAccount.success"),
      });
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const router = useRouter();

const destroyMutation = useDestroyAccountMutation();

const destroy = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.account.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync()
        .then(async () => {
          displaySuccess({
            text: t("messages.account.destroy.success"),
          });

          sessionStore.logout();

          await router.push({ name: "home" }).catch(() => {});
        })
        .catch((error) => {
          console.error(error);

          displayAlert({
            text: t("messages.account.destroy.failure"),
          });
        })
        .finally(() => {
          deleting.value = false;
        });
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};
</script>

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
                <FormInput
                  v-model="username"
                  v-bind="usernameProps"
                  name="username"
                />
                <FormInput
                  v-model="email"
                  v-bind="emailProps"
                  name="email"
                  :type="InputTypesEnum.EMAIL"
                />

                <FormInput
                  v-if="currentUser?.unconfirmedEmail"
                  v-model="currentUser.unconfirmedEmail"
                  name="unconfirmedEmail"
                  :type="InputTypesEnum.EMAIL"
                  :disabled="true"
                  :label="t('labels.user.unconfirmedEmail')"
                  :no-placeholder="true"
                />
                <Btn
                  :loading="submitting"
                  :type="BtnTypesEnum.SUBMIT"
                  :size="BtnSizesEnum.LARGE"
                >
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
            :variant="BtnVariantsEnum.DANGER"
            :size="BtnSizesEnum.LARGE"
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
