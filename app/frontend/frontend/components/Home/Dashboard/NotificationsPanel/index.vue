<script lang="ts">
export default {
  name: "HomeDashboardNotificationsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { type Notification, useNotifications } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const { data, isLoading, isFetching, isLoadingError } = useNotifications(
  { perPage: "5" },
  { query: liveQuery },
);

const notifications = computed(() => data.value?.items || []);

// Only a link into the app becomes a route; anything else opens from the
// notifications page, which knows how to handle it.
const linkFor = (notification: Notification) =>
  notification.link?.startsWith("/") ? notification.link : undefined;
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.notifications.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!notifications.length"
    :more="{ name: 'notifications' }"
    data-test="home-notifications"
  >
    <div class="home-notifications">
      <RowListItem
        v-for="notification in notifications"
        :key="notification.id"
        :to="linkFor(notification)"
        :class="{ 'home-notifications__unread': !notification.read }"
      >
        <template #leading>
          <i
            :class="[
              notification.icon || 'fa-duotone fa-bell',
              'home-notifications__icon',
            ]"
            aria-hidden="true"
          />
        </template>
        <template #name>{{ notification.title }}</template>
        <template #sub>
          <time :datetime="notification.createdAt">
            {{ l(notification.createdAt, "datetime.formats.short") }}
          </time>
        </template>
      </RowListItem>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-bell"
        :title="t('home.dashboard.notifications.empty')"
      />
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-notifications {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.home-notifications__icon {
  width: 20px;
  color: var(--color-muted, #7a8288);
  text-align: center;
}

.home-notifications__unread .home-notifications__icon {
  color: var(--color-primary, #428bca);
}
</style>
