<script lang="ts">
export default {
  name: "AppNotificationsMessageBody",
};
</script>

<script lang="ts" setup>
import { appNotificationDismissKey } from "@/shared/components/AppNotifications/types";
import { useI18n } from "@/shared/composables/useI18n";
import { sanitizeHtml } from "@/shared/utils/SafeHtml";

type Props = {
  text?: string;
};

const props = withDefaults(defineProps<Props>(), {
  text: undefined,
});

const safeText = computed(() => (props.text ? sanitizeHtml(props.text) : ""));

const { t } = useI18n();

const dismiss = inject(appNotificationDismissKey, undefined);

const onClose = () => {
  dismiss?.();
};
</script>

<template>
  <div class="app-notifications__message-body">
    <div class="app-notifications__message-body__inner">
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-if="text" v-html="safeText" />
      <slot v-else />
    </div>

    <button
      type="button"
      class="app-notifications__message-body__close"
      :aria-label="t('actions.close')"
      data-test="notification-close"
      @click.stop="onClose"
    >
      <i class="fa-light fa-times" />
    </button>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
