<script lang="ts">
export default {
  name: "SettingsNotificationsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Loader from "@/shared/components/Loader/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import {
  type NotificationPreference,
  NotificationTypeEnum,
  getNotificationPreferencesQueryKey,
  useNotificationPreferences,
  useUpdateNotificationPreference,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
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

const CHANNELS = ["app", "mail", "push"] as const;

type Channel = (typeof CHANNELS)[number];

const { data: preferences, isLoading, refetch } = useNotificationPreferences();

const updateMutation = useUpdateNotificationPreference();

const queryClient = useQueryClient();

const prefByType = computed<Record<string, NotificationPreference>>(() =>
  Object.fromEntries(
    (preferences.value ?? []).map((preference) => [
      preference.notificationType,
      preference,
    ]),
  ),
);

const supportsChannel = (
  preference: NotificationPreference | undefined,
  channel: Channel,
) => {
  if (!preference) {
    return false;
  }

  if (channel === "mail") {
    return !!preference.mailAvailable;
  }

  if (channel === "push") {
    return !!preference.pushAvailable;
  }

  return true;
};

// A channel nothing can deliver on is not a column of dead switches: push has
// no sender yet, so it stays out of the table until one type reports it.
const channels = computed(() =>
  CHANNELS.filter((channel) =>
    channel === "app"
      ? true
      : (preferences.value ?? []).some((preference) =>
          supportsChannel(preference, channel),
        ),
  ),
);

const columns = computed(() => `1fr repeat(${channels.value.length}, 80px)`);

const typesWith = (types: NotificationTypeEnum[], channel: Channel) =>
  types.filter((type) => supportsChannel(prefByType.value[type], channel));

// The group switch reads as on only when every type under it is, so it is
// never on while something below it is off.
const groupEnabled = (types: NotificationTypeEnum[], channel: Channel) => {
  const relevant = typesWith(types, channel);

  return (
    relevant.length > 0 &&
    relevant.every((type) => prefByType.value[type]?.[channel])
  );
};

const write = (
  preference: NotificationPreference,
  channel: Channel,
  next: boolean,
) =>
  updateMutation.mutateAsync({
    id: preference.notificationType as NotificationTypeEnum,
    data: {
      app: channel === "app" ? next : preference.app,
      mail: channel === "mail" ? next : preference.mail,
      push: channel === "push" ? next : preference.push,
    },
  });

// The switch has already moved under the pointer, so the cache moves with it
// and the refetch below only confirms it. Without this the toggle springs back
// for as long as the round trip takes.
const patchCached = (
  types: NotificationTypeEnum[],
  channel: Channel,
  next: boolean,
) => {
  queryClient.setQueryData<NotificationPreference[]>(
    getNotificationPreferencesQueryKey(),
    (data) =>
      data?.map((preference) =>
        types.includes(preference.notificationType as NotificationTypeEnum)
          ? { ...preference, [channel]: next }
          : preference,
      ),
  );
};

const submit = async (
  types: NotificationTypeEnum[],
  channel: Channel,
  next: boolean,
) => {
  const writable = typesWith(types, channel);

  if (!writable.length) {
    return;
  }

  patchCached(writable, channel, next);

  try {
    await Promise.all(
      writable.map((type) => write(prefByType.value[type], channel, next)),
    );
  } catch {
    displayAlert({ text: t("messages.updateNotifications.failure") });
  } finally {
    await refetch();
  }
};

const toggleType = (
  type: NotificationTypeEnum,
  channel: Channel,
  next: boolean,
) => submit([type], channel, next);

const toggleGroup = (
  group: { types: NotificationTypeEnum[] },
  channel: Channel,
  next: boolean,
) => submit(group.types, channel, next);
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.notifications") }}</Heading>

  <Teleport to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.notifications.openCenter')"
      :to="{ name: 'notifications' }"
      mobile-icon-only
    >
      <i class="fa-duotone fa-bell" />
      {{ t("actions.notifications.openCenter") }}
    </Btn>
  </Teleport>

  <p class="notification-prefs__hint">
    {{ t("texts.settings.notifications.hint") }}
  </p>

  <Loader :loading="isLoading" />

  <Panel v-for="group in groups" :key="group.key">
    <PanelHeading :level="HeadingLevelEnum.H2">
      {{ t(`labels.notificationTypes.groups.${group.key}`) }}
    </PanelHeading>

    <PanelBody>
      <div
        class="notification-prefs"
        :style="{ '--notification-prefs-columns': columns }"
        :data-test="`notification-prefs-${group.key}`"
      >
        <div class="notification-prefs__row notification-prefs__row--head">
          <span />
          <span
            v-for="channel in channels"
            :key="channel"
            class="notification-prefs__channel"
          >
            {{ t(`labels.notificationTypes.channels.${channel}`) }}
          </span>
        </div>

        <div class="notification-prefs__row notification-prefs__row--all">
          <span class="notification-prefs__label">
            {{ t("labels.notificationTypes.allInGroup") }}
          </span>
          <span
            v-for="channel in channels"
            :key="channel"
            class="notification-prefs__cell"
          >
            <span class="notification-prefs__cell-label">
              {{ t(`labels.notificationTypes.channels.${channel}`) }}
            </span>
            <FormToggle
              :model-value="groupEnabled(group.types, channel)"
              :disabled="!typesWith(group.types, channel).length"
              :name="`pref-${group.key}-${channel}`"
              no-label
              @update:model-value="
                (value) => toggleGroup(group, channel, value)
              "
            />
          </span>
        </div>

        <div
          v-for="type in group.types"
          :key="type"
          class="notification-prefs__row"
        >
          <span class="notification-prefs__label">
            {{ t(`labels.notificationTypes.${type}`) }}
          </span>
          <span
            v-for="channel in channels"
            :key="channel"
            class="notification-prefs__cell"
          >
            <template v-if="supportsChannel(prefByType[type], channel)">
              <span class="notification-prefs__cell-label">
                {{ t(`labels.notificationTypes.channels.${channel}`) }}
              </span>
              <FormToggle
                :model-value="prefByType[type]?.[channel]"
                :name="`pref-${type}-${channel}`"
                no-label
                @update:model-value="
                  (value) => toggleType(type, channel, value)
                "
              />
            </template>
            <!-- A type that cannot reach a channel says so with a dash rather
               than a switch that would never move. -->
            <span
              v-else
              class="notification-prefs__unavailable"
              aria-hidden="true"
            >
              &mdash;
            </span>
          </span>
        </div>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.notification-prefs__hint {
  max-width: 60ch;
  margin: 0 0 20px;
  color: $gray-lighter;
}

.notification-prefs {
  display: flex;
  flex-direction: column;
  margin-top: 6px;

  // A switch in a table cell carries no spacing of its own - `FormToggle` is
  // built for a form column, where the margin separates it from the next field.
  :deep(.form-toggle) {
    margin-bottom: 0;
  }
}

.notification-prefs__row {
  display: grid;
  grid-template-columns: var(--notification-prefs-columns);
  align-items: center;
  gap: 10px;
  padding: 6px 0;
  border-top: 1px solid rgba(#fff, 0.06);
}

// The header carries the column names, so it has no line above it and the
// group switch below it does.
.notification-prefs__row--head {
  padding-bottom: 2px;
  color: $gray-lighter;
  font-size: 0.8em;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-top: 0;
}

.notification-prefs__row--all {
  font-weight: bold;
}

.notification-prefs__channel,
.notification-prefs__cell {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 32px;
}

.notification-prefs__label {
  min-width: 0;
}

.notification-prefs__cell-label {
  display: none;
}

.notification-prefs__unavailable {
  color: $gray-lighter;
  opacity: 0.5;
}

// No room for a column per channel on a phone: the row becomes a label with its
// switches under it, and each switch has to name its own channel, which is what
// the header did on a wide screen.
@media (max-width: $tablet-breakpoint) {
  .notification-prefs__row {
    grid-template-columns: 1fr;
    gap: 4px;
    padding: 10px 0;
  }

  .notification-prefs__row--head {
    display: none;
  }

  .notification-prefs__cell {
    justify-content: flex-start;
    gap: 10px;
    min-height: 28px;
    padding-left: 12px;
  }

  .notification-prefs__cell-label {
    display: inline;
    min-width: 44px;
    color: $gray-lighter;
    font-size: 0.85em;
    font-weight: normal;
  }

  .notification-prefs__unavailable {
    display: none;
  }
}
</style>
