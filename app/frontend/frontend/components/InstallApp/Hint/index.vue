<script lang="ts">
export default {
  name: "InstallAppHint",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useInstallPrompt,
  type InstallPromptContext,
} from "@/frontend/composables/useInstallPrompt";
import { useNotificationsStore } from "@/shared/stores/notifications";

interface Props {
  context: InstallPromptContext;
  notificationId?: string;
}

const props = withDefaults(defineProps<Props>(), {
  notificationId: undefined,
});

const { t } = useI18n();

const { install } = useInstallPrompt();

const notificationsStore = useNotificationsStore();

const closeNotification = () => {
  if (props.notificationId) {
    notificationsStore.hideMessage(props.notificationId);
  }
};

const installApp = async (event: MouseEvent) => {
  event.stopPropagation();
  closeNotification();
  await install();
};

const later = (event: MouseEvent) => {
  event.stopPropagation();
  closeNotification();
};
</script>

<template>
  <MessageBody>
    <div class="install-app-hint">
      <div class="install-app-hint__heading">
        <i class="fa-light fa-mobile-screen install-app-hint__icon" />
        <strong>{{ t("headlines.installApp.offer") }}</strong>
      </div>
      <p class="install-app-hint__body">
        {{ t(`texts.installApp.${context}`) }}
      </p>
      <div class="install-app-hint__actions">
        <Btn data-test="install-app-hint-cta" @click="installApp">
          {{ t("actions.installApp.cta") }}
        </Btn>
        <Btn
          data-test="install-app-hint-later"
          :variant="BtnVariantsEnum.BARE"
          @click="later"
        >
          {{ t("actions.installApp.later") }}
        </Btn>
      </div>
    </div>
  </MessageBody>
</template>

<style lang="scss" scoped>
.install-app-hint {
  width: 100%;

  &__heading {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.4rem;

    strong {
      font-size: 0.95rem;
    }
  }

  &__icon {
    color: #fff;
    opacity: 0.85;
  }

  &__body {
    margin: 0 0 0.75rem;
    line-height: 1.4;
    font-size: 0.85rem;
    opacity: 0.95;
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    align-items: center;
  }
}
</style>
