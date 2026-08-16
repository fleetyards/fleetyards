<script lang="ts">
export default {
  name: "AdminNotificationsPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/admin/components/Notifications/FilterForm/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useAdminNotificationFilters } from "@/admin/composables/useAdminNotificationFilters";
import { useAdminNotificationUpdates } from "@/admin/composables/useAdminNotificationUpdates";
import {
  useAdminNotifications as useAdminNotificationsQuery,
  getAdminNotificationsQueryKey,
  readAdminNotification,
  readAllAdminNotifications,
  destroyAdminNotification,
  destroyAllAdminNotifications,
  type AdminNotification,
  type AdminNotificationSortEnum,
  AdminNotificationSeverityEnum,
} from "@/services/fyAdminApi";

const { t, l } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const route = useRoute();

const sorts = computed((): AdminNotificationSortEnum[] => {
  return route.query.s ? [route.query.s as AdminNotificationSortEnum] : [];
});

const queryKey = computed(() =>
  getAdminNotificationsQueryKey(queryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(queryKey);

const { filters, isFilterSelected } = useAdminNotificationFilters(async () => {
  await refetch();
});

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    ...filters.value,
    sorts: sorts.value,
  },
}));

const {
  data: notifications,
  refetch,
  ...asyncStatus
} = useAdminNotificationsQuery(queryParams);

const { invalidate } = useAdminNotificationUpdates(ref(true));

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const columns: BaseTableCol<AdminNotification>[] = [
  {
    name: "severity",
    label: "Severity",
    width: "120px",
    alignment: "center",
  },
  {
    name: "title",
    label: "Notification",
    flexGrow: 1,
  },
  {
    name: "type",
    label: "Type",
    mobile: false,
    width: "220px",
  },
  {
    name: "createdAt",
    label: "Created at",
    mobile: false,
    sortable: true,
    width: "200px",
  },
];

const expanded = ref<string[]>([]);

const isExpanded = (notification: AdminNotification) =>
  expanded.value.includes(notification.id);

const toggle = (notification: AdminNotification) => {
  if (isExpanded(notification)) {
    expanded.value = expanded.value.filter((id) => id !== notification.id);
    return;
  }

  expanded.value = [...expanded.value, notification.id];
};

const severityVariant = (severity: AdminNotification["severity"]) => {
  switch (severity) {
    case AdminNotificationSeverityEnum.ERROR:
      return "danger";
    case AdminNotificationSeverityEnum.WARNING:
      return "warning";
    default:
      return "default";
  }
};

const withFeedback = async (
  action: () => Promise<unknown>,
  message: string,
) => {
  try {
    await action();
    invalidate();
    displaySuccess({ text: message });
  } catch {
    displayAlert({ text: t("messages.adminNotifications.error") });
  }
};

const markRead = (notification: AdminNotification) =>
  withFeedback(
    () => readAdminNotification(notification.id),
    t("messages.adminNotifications.read"),
  );

const markAllRead = () =>
  withFeedback(
    () => readAllAdminNotifications(),
    t("messages.adminNotifications.readAll"),
  );

const destroy = (notification: AdminNotification) =>
  withFeedback(
    () => destroyAdminNotification(notification.id),
    t("messages.adminNotifications.destroyed"),
  );

const destroyAll = () =>
  withFeedback(
    () => destroyAllAdminNotifications(),
    t("messages.adminNotifications.destroyedAll"),
  );
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.notifications.index") }}
    <HeadingSmall v-if="notifications">
      {{
        t("headlines.pagination.count", {
          current: notifications?.items.length,
          total: notifications?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.adminNotifications.readAll')"
      mobile-icon-only
      @click="markAllRead"
    >
      <i class="fa-duotone fa-check-double" />
      {{ t("actions.adminNotifications.readAll") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.adminNotifications.destroyAll')"
      :tone="BtnTonesEnum.DANGER"
      mobile-icon-only
      @click="destroyAll"
    >
      <i class="fa-duotone fa-trash" />
      {{ t("actions.adminNotifications.destroyAll") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-notifications"
    :records="notifications?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="notifications?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="createdAt desc"
      >
        <template #col-severity="{ record }">
          <BasePill :variant="severityVariant(record.severity)" uppercase>
            {{ t(`labels.adminNotifications.severities.${record.severity}`) }}
          </BasePill>
        </template>
        <template #col-title="{ record }">
          <div
            class="admin-notification-title"
            :class="{ 'admin-notification-title--unread': !record.read }"
          >
            <button
              v-if="record.body"
              type="button"
              class="admin-notification-toggle"
              @click="toggle(record)"
            >
              <i
                :class="
                  isExpanded(record)
                    ? 'fa-duotone fa-chevron-down'
                    : 'fa-duotone fa-chevron-right'
                "
              />
            </button>
            <span>{{ record.title }}</span>
            <span
              v-if="record.occurrences > 1"
              class="admin-notification-count"
            >
              &times;{{ record.occurrences }}
            </span>
            <router-link v-if="record.link" :to="record.link">
              <i class="fa-duotone fa-arrow-up-right-from-square" />
            </router-link>
          </div>
          <pre v-if="isExpanded(record)" class="admin-notification-body">{{
            record.body
          }}</pre>
        </template>
        <template #col-type="{ record }">
          {{ t(`labels.adminNotifications.types.${record.notificationType}`) }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <Btn v-if="!record.read" @click.prevent="markRead(record)">
            <i class="fa-duotone fa-check" />
            {{ t("actions.adminNotifications.read") }}
          </Btn>
          <Btn :tone="BtnTonesEnum.DANGER" @click.prevent="destroy(record)">
            <i class="fa-duotone fa-trash" />
            {{ t("actions.delete") }}
          </Btn>
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="notifications"
        :query-result-ref="notifications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="notifications"
        :query-result-ref="notifications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.admin-notification-title {
  display: flex;
  align-items: center;
  gap: 8px;

  &--unread {
    font-weight: bold;
  }
}

.admin-notification-toggle {
  padding: 0;
  color: inherit;
  background: none;
  border: 0;
  cursor: pointer;
}

.admin-notification-count {
  color: $gray-lighter;
  font-size: 0.85em;
}

.admin-notification-body {
  margin: 8px 0 0;
  padding: 10px;
  max-height: 320px;
  overflow: auto;
  color: $text-color;
  font-size: 0.85em;
  white-space: pre-wrap;
  background-color: rgba($gray-darker, 0.6);
  border-radius: $border-radius-base;
}
</style>
