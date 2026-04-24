<script lang="ts">
export default {
  name: "SettingsSecurityStatus",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ChangePasswordForm from "@/frontend/components/Security/ChangePasswordForm/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const sessionStore = useSessionStore();
void sessionStore.refreshUser();

const { t } = useI18n();

const router = useRouter();

const { displayConfirm } = useAppNotifications();

const generateBackupCodes = () => {
  displayConfirm({
    text: t("messages.confirm.twoFactor.generateBackupCodes"),
    onConfirm: async () => {
      await router.push({ name: "settings-two-factor-backup-codes" });
    },
  });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.security.index") }}</Heading>

  <div v-if="sessionStore.currentUser" class="row">
    <div class="col-12">
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
              <BasePill
                v-if="sessionStore.currentUser.twoFactorRequired"
                variant="success"
              >
                <i class="fa-solid fa-check" />
                {{ t("labels.enabled") }}
              </BasePill>
              <BasePill v-else variant="danger">
                <i class="fa-solid fa-times" />
                {{ t("labels.disabled") }}
              </BasePill>
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
