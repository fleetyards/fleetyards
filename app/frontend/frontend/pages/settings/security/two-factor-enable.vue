<script lang="ts">
import { disabledRouteGuard } from "@/frontend/utils/RouteGuards/TwoFactor";

export default {
  name: "TwoFactorEnable",
  beforeRouteEnter: disabledRouteGuard,
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import BackupCodesPanel from "@/frontend/components/Security/TwoFactorBackupCodesPanel/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useForm } from "vee-validate";
import {
  useStartOtpSetup as useStartOtpSetupMutation,
  useEnableOtpSetup as useEnableOtpSetupMutation,
  type ValidationError,
} from "@/services/fyApi";
import { type ErrorType } from "@/services/fyApi/axiosClient";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const comlink = useComlink();

const submitting = ref(false);

const started = ref(false);

const backupCodes = ref<string[]>();

const validationSchema = {
  twoFactorCode: "required",
};

const { defineField, handleSubmit } = useForm({
  validationSchema,
});

const [twoFactorCode, twoFactorCodeProps] = defineField("twoFactorCode");

onMounted(() => {
  startProcess();
});

onBeforeUnmount(() => {
  comlink.off("access-confirmed");
});

const startMutation = useStartOtpSetupMutation();

const startProcess = async () => {
  await startMutation
    .mutateAsync()
    .then(() => {
      started.value = true;
      comlink.emit("user-update");
    })
    .catch((error) => {
      console.error(error);
      displayAlert({
        text: t("messages.twoFactor.enable.failure"),
      });
    });
};

const enableMutation = useEnableOtpSetupMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await enableMutation
    .mutateAsync({
      data: values,
    })
    .then((data) => {
      comlink.emit("user-update");

      backupCodes.value = data.codes;

      displaySuccess({
        text: t("messages.twoFactor.enable.success"),
      });
    })
    .catch((error) => {
      const response = error as unknown as ErrorType<ValidationError>;

      if (response.code === "requires_access_confirmation") {
        comlink.emit("access-confirmation-required");
      } else {
        displayAlert({
          text: t("messages.twoFactor.enable.failure"),
        });
      }
    })
    .finally(() => {
      submitting.value = false;
    });
});

const copyProvisioningUrl = () => {
  if (!currentUser?.value || !currentUser.value.twoFactorProvisioningUrl) {
    return;
  }

  copyText(currentUser.value.twoFactorProvisioningUrl).then(
    () => {
      displaySuccess({
        text: t("messages.copyTwoFactorProvisioningUrl.success"),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copyTwoFactorProvisioningUrl.failure"),
      });
    },
  );
};
</script>

<template>
  <Heading>{{ t("headlines.settings.twoFactor.enable") }}</Heading>

  <div v-if="backupCodes" class="row two-factor-backup-codes">
    <div class="col-12 col-md-6 offset-md-3">
      <BackupCodesPanel :codes="backupCodes" />
      <Btn
        :to="{ name: 'settings-security', hash: '#two-factor' }"
        :exact="true"
      >
        {{ t("actions.done") }}
      </Btn>
    </div>
  </div>

  <div
    v-else-if="currentUser && !currentUser.twoFactorRequired && started"
    class="row"
  >
    <div class="col-12">
      <p>
        {{ t("texts.twoFactor.enable") }}
      </p>
      <form class="two-factor-form" @submit.prevent="onSubmit">
        <div class="row">
          <div class="col-12 two-factor-form-inner">
            <div class="two-factor-qrcode">
              <img
                :src="currentUser.twoFactorQrCodeUrl"
                alt="two-factor-qrcode"
              />

              <code
                class="two-factor-provisioning-url"
                @click="copyProvisioningUrl"
              >
                {{ currentUser.twoFactorProvisioningUrl }}
              </code>
            </div>
            <FormInput
              v-model="twoFactorCode"
              name="twoFactorCode"
              v-bind="twoFactorCodeProps"
              class="two-factor-input"
              :autofocus="true"
              :no-label="true"
              translation-key="twoFactorCode"
            />

            <br />

            <Btn :loading="submitting" type="submit" size="large" :block="true">
              {{ t("actions.twoFactor.enable") }}
            </Btn>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.two-factor-form {
  display: flex;
  justify-content: center;
  margin: 40px 0;

  .two-factor-form-inner {
    width: 400px;
  }
}

.two-factor-provisioning-url {
  font-size: 70%;
  cursor: copy;
}

.two-factor-qrcode {
  margin-bottom: 20px;
  text-align: center;

  img {
    max-width: 250px;
    margin-bottom: 20px;
  }
}
</style>
