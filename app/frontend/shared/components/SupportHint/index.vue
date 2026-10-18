<script lang="ts">
export default {
  name: "SupportHint",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useModalQuery } from "@/frontend/composables/useModalQuery";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";
import type { SupportPromptContext } from "@/shared/composables/useSupportPrompt";
import { useNotificationsStore } from "@/shared/stores/notifications";

type Props = {
  context: SupportPromptContext;
  meta?: Record<string, unknown>;
  inline?: boolean;
  notificationId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  meta: () => ({}),
  inline: false,
  notificationId: undefined,
});

const emit = defineEmits<{
  (event: "dismiss"): void;
}>();

const { t } = useI18n();

const { openModal } = useModalQuery();
const { recordShown } = useSupportPrompt();
const notificationsStore = useNotificationsStore();

onMounted(() => {
  recordShown();
});

const closeNotification = () => {
  if (props.notificationId) {
    notificationsStore.hideMessage(props.notificationId);
  }
};

const headlineKey = computed(() => `headlines.supportHint.${props.context}`);
const bodyKey = computed(() => `texts.supportHint.${props.context}`);

const openSupportModal = (event: MouseEvent) => {
  event.stopPropagation();
  void openModal("support");
  closeNotification();
  emit("dismiss");
};

const dismissInline = (event: MouseEvent) => {
  event.stopPropagation();
  emit("dismiss");
};
</script>

<template>
  <!-- A notice among the content it follows, so it is one: asking, not
       warning, hence neutral. -->
  <Alert
    v-if="inline"
    class="support-hint support-hint--inline"
    :variant="AlertVariantsEnum.NEUTRAL"
    :size="AlertSizesEnum.COMPACT"
    icon="fa-duotone fa-heart"
    :title="t(headlineKey)"
  >
    <span class="support-hint__body" v-html="t(bodyKey, meta)" />
    <!-- Under the text rather than in the alert's actions: beside a body this
         long they squeezed it into a narrow column. -->
    <span class="support-hint__actions">
      <Btn
        :variant="BtnVariantsEnum.GHOST"
        data-test="support-hint-cta"
        @click="openSupportModal"
      >
        {{ t("actions.supportHint.cta") }}
      </Btn>
      <Btn
        data-test="support-hint-dismiss"
        @click="dismissInline"
        :variant="BtnVariantsEnum.BARE"
      >
        {{ t("actions.supportHint.later") }}
      </Btn>
    </span>
  </Alert>
  <MessageBody v-else>
    <div class="support-hint support-hint--notification">
      <div class="support-hint__heading">
        <i class="fa-light fa-heart support-hint__icon" />
        <strong>{{ t(headlineKey) }}</strong>
      </div>
      <p class="support-hint__body" v-html="t(bodyKey, meta)" />
      <Btn data-test="support-hint-cta" @click="openSupportModal">
        {{ t("actions.supportHint.cta") }}
      </Btn>
    </div>
  </MessageBody>
</template>

<style lang="scss" scoped>
@import "./index";
</style>
