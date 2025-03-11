<script lang="ts">
export default {
  name: "SettingsSecurityStatus",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import ChangePasswordForm from "@/frontend/components/Security/ChangePasswordForm/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";

const sessionStore = useSessionStore();

const { t } = useI18n();

const router = useRouter();

const generateBackupCodes = () => {
  displayConfirm({
    text: t("messages.confirm.twoFactor.generateBackupCodes"),
    onConfirm: () => {
      router.push({ name: "settings-two-factor-backup-codes" });
    },
  });
};
</script>

<template>
  <div v-if="sessionStore.currentUser" class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ t("headlines.settings.security.index") }}</h1>
        </div>
      </div>
      <br />
      <div class="row">
        <div class="col-12 col-md-6">
          <h2 id="change-password">{{ t("headlines.changePassword") }}</h2>
          <ChangePasswordForm />
        </div>
      </div>

      <hr />

      <div class="row">
        <div class="col-12 col-md-6">
          <h2 id="two-factor">
            {{ t("headlines.settings.security.twoFactor") }}
            <small>
              <span
                v-if="sessionStore.currentUser.twoFactorRequired"
                class="badge badge-success"
              >
                <i class="fas fa-check" />
                {{ t("labels.enabled") }}
              </span>
              <span v-else class="badge badge-danger">
                <i class="fas fa-times" />
                {{ t("labels.disabled") }}
              </span>
            </small>
          </h2>
          <div class="two-factor-actions">
            <template v-if="sessionStore.currentUser.twoFactorRequired">
              <Btn :to="{ name: 'settings-two-factor-disable' }">
                {{ t("actions.twoFactor.disable") }}
              </Btn>
              <Btn @click="generateBackupCodes">
                {{ t("actions.twoFactor.generateBackupCodes") }}
              </Btn>
            </template>
            <Btn v-else :to="{ name: 'settings-two-factor-enable' }">
              {{ t("actions.twoFactor.enable") }}
            </Btn>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.two-factor-status {
  margin-bottom: 20px;
  font-size: 200%;
}

.two-factor-actions {
  display: flex;
  margin-top: 20px;
}
</style>
