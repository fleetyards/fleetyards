<script lang="ts">
export default {
  name: "VisualTestsNotificationCtaDemo",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";
import { useNotificationsStore } from "@/shared/stores/notifications";

type Props = {
  title: string;
  body: string;
  ctaLabel: string;
  notificationId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  notificationId: undefined,
});

const notificationsStore = useNotificationsStore();

const onCta = (event: MouseEvent) => {
  event.stopPropagation();
  if (props.notificationId) {
    notificationsStore.hideMessage(props.notificationId);
  }
};
</script>

<template>
  <MessageBody>
    <div class="notification-cta-demo">
      <b>{{ title }}</b>
      <p>{{ body }}</p>
      <Btn
        :size="BtnSizesEnum.X_SMALL"
        :inline="true"
        data-test="notification-cta-button"
        @click="onCta"
      >
        {{ ctaLabel }}
      </Btn>
    </div>
  </MessageBody>
</template>

<style lang="scss" scoped>
.notification-cta-demo {
  display: flex;
  flex-direction: column;
  align-items: flex-start;

  b {
    margin-bottom: 0.25rem;
  }

  p {
    margin: 0 0 0.75rem;
  }
}
</style>
