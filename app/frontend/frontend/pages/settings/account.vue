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
import FormActions from "@/shared/components/base/FormActions/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useForm } from "vee-validate";
import { type AccountUpdateInput } from "@/services/fyApi";
import {
  BtnVariantsEnum,
  BtnSizesEnum,
} from "@/shared/components/base/Btn/types";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import {
  useUpdateAccount as useUpdateAccountMutation,
  useDestroyAccount as useDestroyAccountMutation,
  type ValidationError,
} from "@/services/fyApi";
import { type AxiosError } from "axios";

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

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

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

const runDestroy = async (destroyFleets: boolean) => {
  await destroyMutation
    .mutateAsync({
      params: destroyFleets ? { destroy_fleets: true } : undefined,
    })
    .then(async () => {
      displaySuccess({
        text: t("messages.account.destroy.success"),
      });

      await sessionStore.logout();

      await router.push({ name: "home" }).catch(() => {});
    })
    .catch((error) => {
      const response = (error as AxiosError<ValidationError>).response;
      const data = response?.data;
      const baseError = data?.errors
        ?.find((field) => field.attribute === "base")
        ?.messages?.find(
          (message) => message.code === "has_permanent_fleet_memberships",
        );

      if (baseError && !destroyFleets) {
        const fleets =
          baseError.message.match(
            /admin of the following fleets?: ([^.]+)\./i,
          )?.[1] ?? baseError.message;

        deleting.value = true;
        setTimeout(() => {
          displayConfirm({
            text: t("messages.confirm.account.destroyWithFleets", { fleets }),
            onConfirm: () => {
              void runDestroy(true);
            },
            onClose: () => {
              deleting.value = false;
            },
          });
        }, 0);
        return;
      }

      const fallback =
        data?.errors
          ?.flatMap((field) => field.messages.map((m) => m.message))
          ?.join(" ") ||
        data?.message ||
        t("messages.account.destroy.failure");

      displayAlert({ text: fallback });
    })
    .finally(() => {
      deleting.value = false;
    });
};

const destroy = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.account.destroy"),
    onConfirm: () => {
      void runDestroy(false);
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.account") }}</Heading>

  <form id="settings-account-form" @submit.prevent="updateAccount">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="username" v-bind="usernameProps" name="username" />
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
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="settings-account-form"
      hide-cancel
    />
  </form>

  <hr />

  <div class="row">
    <div class="col-12">
      <br />
      <p>
        {{ t("labels.account.destroyInfo") }}
      </p>
      <div class="text-center">
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
</template>
