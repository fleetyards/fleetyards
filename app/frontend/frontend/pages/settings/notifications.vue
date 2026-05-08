<script lang="ts">
export default {
  name: "SettingsNotificationsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import {
  type NotificationPreference,
  NotificationTypeEnum,
  useNotificationPreferences,
  useUpdateNotificationPreference,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const { displayAlert } = useAppNotifications();

const groups: Array<{ key: string; types: NotificationTypeEnum[] }> = [
  {
    key: "account",
    types: [
      NotificationTypeEnum.HANGAR_CREATE,
      NotificationTypeEnum.HANGAR_DESTROY,
      NotificationTypeEnum.HANGAR_SYNC_FINISHED,
      NotificationTypeEnum.HANGAR_SYNC_FAILED,
      NotificationTypeEnum.WISHLIST_CREATE,
      NotificationTypeEnum.WISHLIST_DESTROY,
      NotificationTypeEnum.MODEL_ON_SALE,
      NotificationTypeEnum.NEW_MODEL,
    ],
  },
  {
    key: "fleetMembership",
    types: [
      NotificationTypeEnum.FLEET_INVITE,
      NotificationTypeEnum.FLEET_MEMBER_REQUESTED,
      NotificationTypeEnum.FLEET_MEMBER_ACCEPTED,
      NotificationTypeEnum.FLEET_REQUEST_ACCEPTED,
      NotificationTypeEnum.FLEET_INVENTORY_ITEM_ADDED,
    ],
  },
  {
    key: "fleetEvents",
    types: [
      NotificationTypeEnum.FLEET_EVENT_PUBLISHED,
      NotificationTypeEnum.FLEET_EVENT_LOCKED,
      NotificationTypeEnum.FLEET_EVENT_STARTING_SOON,
      NotificationTypeEnum.FLEET_EVENT_STARTED,
      NotificationTypeEnum.FLEET_EVENT_COMPLETED,
      NotificationTypeEnum.FLEET_EVENT_CANCELLED,
      NotificationTypeEnum.FLEET_EVENT_SIGNUP_ADDED,
      NotificationTypeEnum.FLEET_EVENT_SIGNUP_WITHDRAWN,
      NotificationTypeEnum.FLEET_EVENT_SIGNUP_CONFIRMED,
      NotificationTypeEnum.FLEET_EVENT_SIGNUP_ASSIGNED,
      NotificationTypeEnum.FLEET_EVENT_SIGNUP_KICKED,
    ],
  },
];

const channels = ["app", "mail", "push"] as const;
type Channel = (typeof channels)[number];

const { data: preferences, refetch } = useNotificationPreferences();

const updateMutation = useUpdateNotificationPreference();

const prefByType = computed<Record<string, NotificationPreference>>(() => {
  const map: Record<string, NotificationPreference> = {};
  for (const pref of preferences.value ?? []) {
    map[pref.notificationType] = pref;
  }
  return map;
});

const togglePref = async (
  type: NotificationTypeEnum,
  channel: Channel,
  next: boolean,
) => {
  const current = prefByType.value[type];
  if (!current) return;

  await updateMutation
    .mutateAsync({
      id: type,
      data: {
        app: channel === "app" ? next : current.app,
        mail: channel === "mail" ? next : current.mail,
        push: channel === "push" ? next : current.push,
      },
    })
    .then(() => refetch())
    .catch(() => {
      displayAlert({ text: t("messages.updateNotifications.failure") });
    });
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.notifications") }}</Heading>

  <section
    v-for="group in groups"
    :key="group.key"
    class="notification-prefs-group"
  >
    <h3>{{ t(`labels.notificationTypes.groups.${group.key}`) }}</h3>
    <table class="notification-prefs">
      <thead>
        <tr>
          <th />
          <th
            v-for="channel in channels"
            :key="channel"
            class="notification-prefs__channel"
          >
            {{ t(`labels.notificationTypes.channels.${channel}`) }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="type in group.types" :key="type">
          <td class="notification-prefs__label">
            {{ t(`labels.notificationTypes.${type}`) }}
          </td>
          <td
            v-for="channel in channels"
            :key="channel"
            class="notification-prefs__cell"
          >
            <FormToggle
              v-if="prefByType[type]"
              :model-value="prefByType[type][channel]"
              :disabled="channel === 'mail' && !prefByType[type].mailAvailable"
              :name="`pref-${type}-${channel}`"
              no-label
              @update:model-value="(value) => togglePref(type, channel, value)"
            />
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<style lang="scss" scoped>
.notification-prefs-group {
  margin-bottom: 2rem;

  h3 {
    margin-bottom: 0.6rem;
    font-size: 1rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
  }
}
.notification-prefs {
  width: 100%;
  border-collapse: collapse;

  th,
  td {
    padding: 0.5rem 0.75rem;
    text-align: left;
  }

  th.notification-prefs__channel,
  td.notification-prefs__cell {
    width: 80px;
    text-align: center;
  }

  tbody tr {
    border-top: 1px solid rgba(255, 255, 255, 0.05);
  }
}
</style>
