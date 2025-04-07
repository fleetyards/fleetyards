<script lang="ts">
import { enabledRouteGuard } from "@/frontend/utils/RouteGuards/TwoFactor";

export default {
  name: "SettingsSecurityTwoFactorBackupCodesPage",
  beforeRouteEnter: enabledRouteGuard,
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BackupCodesPanel from "@/frontend/components/Security/TwoFactorBackupCodesPanel/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { generateOtpBackupCodes, type StandardError } from "@/services/fyApi";
import { type ErrorType } from "@/services/axiosClient";

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

const backupCodes = ref<string[]>();

const comlink = useComlink();

onMounted(() => {
  comlink.on("access-confirmed", generateBackupCodes);
});

onBeforeUnmount(() => {
  comlink.off("access-confirmed", generateBackupCodes);
});

const generateBackupCodes = async () => {
  submitting.value = true;

  await generateOtpBackupCodes()
    .then((data) => {
      backupCodes.value = data.codes;
    })
    .catch((error) => {
      const response = error as unknown as ErrorType<StandardError>;

      console.error(error);

      if (response.response?.data.code === "requires_access_confirmation") {
        comlink.emit("access-confirmation-required");
      } else {
        displayAlert({
          text: t("messages.twoFactor.backupCodes.failure"),
        });
      }
      displayAlert({
        text: t("messages.twoFactor.backupCodes.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
};
</script>

<template>
  <div v-if="sessionStore.currentUser" class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ t("headlines.settings.twoFactor.backupCodes") }}</h1>
        </div>
      </div>
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
    </div>
  </div>
</template>

<style lang="scss">
.two-factor-backup-codes-action {
  margin: 40px 0;
}
</style>
