<script lang="ts">
export default {
  name: "NotificationsPushDevices",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertSizesEnum } from "@/shared/components/base/Alert/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  type PushSubscription as PushDevice,
  getPushSubscriptionsQueryKey,
  useDestroyPushSubscription,
  usePushSubscriptions,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { WebPushStatusEnum, useWebPush } from "@/shared/composables/useWebPush";
import { useSessionStore } from "@/frontend/stores/session";

const emit = defineEmits<{
  changed: [];
}>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const queryClient = useQueryClient();
const sessionStore = useSessionStore();

const userId = () => sessionStore.currentUser?.id ?? "";

const { status, busy, subscriptionId, refresh, enable, disable } = useWebPush();

const { data: devices } = usePushSubscriptions();

const destroyMutation = useDestroyPushSubscription();

const reloadDevices = () =>
  queryClient.invalidateQueries({ queryKey: getPushSubscriptionsQueryKey() });

// A failed check shows as such rather than as "off", which would invite
// turning on what may well be on already.
onMounted(async () => {
  try {
    await refresh(userId());
  } catch {
    // the panel shows the failed state
  } finally {
    await reloadDevices();
  }
});

const run = async (action: () => Promise<unknown>) => {
  try {
    await action();
  } catch {
    displayAlert({ text: t("messages.pushNotifications.failure") });
  } finally {
    await reloadDevices();
    emit("changed");
  }
};

const turnOn = () => run(() => enable(userId()));

const turnOff = () => run(disable);

const remove = (device: PushDevice) =>
  run(() => destroyMutation.mutateAsync({ id: device.id }));

const deviceLabel = (device: PushDevice) => {
  if (device.browser && device.os) {
    return t("texts.settings.notifications.push.device", {
      browser: device.browser,
      os: device.os,
    });
  }

  return (
    device.browser ||
    device.os ||
    t("texts.settings.notifications.push.unknownDevice")
  );
};
</script>

<template>
  <Panel data-test="push-devices">
    <PanelHeading :level="HeadingLevelEnum.H2">
      {{ t("texts.settings.notifications.push.title") }}
    </PanelHeading>

    <PanelBody>
      <p class="push-devices__intro">
        {{ t("texts.settings.notifications.push.intro") }}
      </p>

      <Alert
        v-if="status === WebPushStatusEnum.UNSUPPORTED"
        :size="AlertSizesEnum.COMPACT"
        variant="neutral"
        data-test="push-devices-unsupported"
      >
        {{ t("texts.settings.notifications.push.unsupported") }}
      </Alert>

      <!-- The browser holds this decision now; asking again does nothing. -->
      <Alert
        v-else-if="status === WebPushStatusEnum.DENIED"
        :size="AlertSizesEnum.COMPACT"
        variant="warning"
        data-test="push-devices-denied"
      >
        {{ t("texts.settings.notifications.push.denied") }}
      </Alert>

      <Alert
        v-else-if="status === WebPushStatusEnum.FAILED"
        :size="AlertSizesEnum.COMPACT"
        variant="danger"
        data-test="push-devices-failed"
      >
        {{ t("texts.settings.notifications.push.failed") }}
      </Alert>

      <div v-else class="push-devices__this" data-test="push-devices-this">
        <span>
          {{
            status === WebPushStatusEnum.ON
              ? t("texts.settings.notifications.push.on")
              : t("texts.settings.notifications.push.off")
          }}
        </span>

        <Btn
          v-if="status === WebPushStatusEnum.OFF"
          :loading="busy"
          data-test="push-devices-enable"
          @click="turnOn"
        >
          <i class="fa-duotone fa-bell" />
          {{ t("actions.notifications.pushEnable") }}
        </Btn>
        <Btn
          v-else
          :loading="busy"
          :variant="BtnVariantsEnum.GHOST"
          data-test="push-devices-disable"
          @click="turnOff"
        >
          <i class="fa-duotone fa-bell-slash" />
          {{ t("actions.notifications.pushDisable") }}
        </Btn>
      </div>

      <ul v-if="devices?.length" class="push-devices__list">
        <li
          v-for="device in devices"
          :key="device.id"
          class="push-devices__device"
          data-test="push-devices-device"
        >
          <span>
            {{ deviceLabel(device) }}
            <span
              v-if="device.id === subscriptionId"
              class="push-devices__current"
            >
              {{ t("texts.settings.notifications.push.thisDevice") }}
            </span>
          </span>

          <Btn
            v-if="device.id !== subscriptionId"
            :variant="BtnVariantsEnum.GHOST"
            :tone="BtnTonesEnum.DANGER"
            :aria-label="t('actions.notifications.pushRemove')"
            data-test="push-devices-remove"
            @click="remove(device)"
          >
            <i class="fa-duotone fa-trash" />
            {{ t("actions.notifications.pushRemove") }}
          </Btn>
        </li>
      </ul>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.push-devices__intro {
  max-width: 60ch;
  margin: 0 0 12px;
  color: var(--color-text-dim);
}

.push-devices__this {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.push-devices__list {
  margin: 16px 0 0;
  padding: 0;
  list-style: none;
}

.push-devices__device {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 8px 0;
  border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
}

.push-devices__current {
  margin-left: 6px;
  color: var(--color-text-dim);
  font-size: 0.85em;
}
</style>
