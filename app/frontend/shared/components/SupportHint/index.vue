<script lang="ts">
export default {
  name: "SupportHint",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
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
const comlink = useComlink();
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
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/SupportBtn/Modal/index.vue"),
    wide: true,
  });
  closeNotification();
  emit("dismiss");
};

const dismissInline = (event: MouseEvent) => {
  event.stopPropagation();
  emit("dismiss");
};
</script>

<template>
  <div v-if="inline" class="support-hint support-hint--inline">
    <div class="support-hint__heading">
      <i class="fa-light fa-heart support-hint__icon" />
      <h5>{{ t(headlineKey) }}</h5>
    </div>
    <p class="support-hint__body" v-html="t(bodyKey, meta)" />
    <div class="support-hint__actions">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :inline="true"
        data-test="support-hint-cta"
        @click="openSupportModal"
      >
        {{ t("actions.supportHint.cta") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.LINK"
        :inline="true"
        data-test="support-hint-dismiss"
        @click="dismissInline"
      >
        {{ t("actions.supportHint.later") }}
      </Btn>
    </div>
  </div>
  <MessageBody v-else>
    <div class="support-hint support-hint--notification">
      <div class="support-hint__heading">
        <i class="fa-light fa-heart support-hint__icon" />
        <strong>{{ t(headlineKey) }}</strong>
      </div>
      <p class="support-hint__body" v-html="t(bodyKey, meta)" />
      <Btn
        :size="BtnSizesEnum.X_SMALL"
        :inline="true"
        data-test="support-hint-cta"
        @click="openSupportModal"
      >
        {{ t("actions.supportHint.cta") }}
      </Btn>
    </div>
  </MessageBody>
</template>

<style lang="scss" scoped>
@import "./index";
</style>
