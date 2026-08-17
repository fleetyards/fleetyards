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
import Panel from "@/shared/components/base/Panel/index.vue";
import {
  PanelTonesEnum,
  PanelVariantsEnum,
} from "@/shared/components/base/Panel/types";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/admin/components/Notifications/FilterForm/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useAdminNotificationFilters } from "@/admin/composables/useAdminNotificationFilters";
import { useAdminNotificationInvalidation } from "@/admin/composables/useAdminNotificationUpdates";
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

const oldestFirst = computed(() => route.query.s === "createdAt asc");

const sortLink = computed(() => ({
  query: {
    ...route.query,
    s: oldestFirst.value ? undefined : "createdAt asc",
  },
}));

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

const { invalidate } = useAdminNotificationInvalidation();

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

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

const severityTone = (severity: AdminNotification["severity"]) => {
  switch (severity) {
    case AdminNotificationSeverityEnum.ERROR:
      return PanelTonesEnum.ERROR;
    case AdminNotificationSeverityEnum.WARNING:
      return PanelTonesEnum.HIGHLIGHT;
    default:
      return PanelTonesEnum.NEUTRAL;
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
      :confirm="t('messages.confirm.adminNotifications.destroyAll')"
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
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #actions-left>
      <Btn :to="sortLink" route-active-class="">
        <i
          :class="
            oldestFirst
              ? 'fa-duotone fa-arrow-down-short-wide'
              : 'fa-duotone fa-arrow-up-wide-short'
          "
        />
        {{
          oldestFirst
            ? t("actions.adminNotifications.sortNewest")
            : t("actions.adminNotifications.sortOldest")
        }}
      </Btn>
    </template>
    <template #default="{ records }">
      <TransitionGroup tag="ul" name="fade-list" class="admin-notifications">
        <li
          v-for="notification in records"
          :key="notification.id"
          class="fade-list-item"
        >
          <Panel
            :variant="PanelVariantsEnum.SLIM"
            :tone="severityTone(notification.severity)"
            :outer-spacing="false"
          >
            <div
              class="admin-notification"
              :class="{
                'admin-notification--unread': !notification.read,
              }"
            >
              <i
                class="admin-notification__icon"
                :class="notification.icon || 'fa-duotone fa-bell'"
              />
              <div class="admin-notification__content">
                <div class="admin-notification__title">
                  <span>{{ notification.title }}</span>
                  <span
                    v-if="notification.occurrences > 1"
                    class="admin-notification__count"
                  >
                    &times;{{ notification.occurrences }}
                  </span>
                </div>
                <div class="admin-notification__meta">
                  <BasePill
                    v-if="
                      notification.severity !==
                      AdminNotificationSeverityEnum.INFO
                    "
                    :variant="severityVariant(notification.severity)"
                    uppercase
                  >
                    {{
                      t(
                        `labels.adminNotifications.severities.${notification.severity}`,
                      )
                    }}
                  </BasePill>
                  <span>
                    {{
                      t(
                        `labels.adminNotifications.types.${notification.notificationType}`,
                      )
                    }}
                  </span>
                  <span>{{
                    l(notification.createdAt, "datetime.formats.short")
                  }}</span>
                </div>
                <Markdown
                  v-if="isExpanded(notification)"
                  class="admin-notification__body"
                  :source="notification.body || ''"
                />
              </div>
              <div class="admin-notification__actions">
                <Btn
                  v-if="notification.body"
                  v-tooltip="
                    isExpanded(notification)
                      ? t('actions.hideDetails')
                      : t('actions.showDetails')
                  "
                  @click="toggle(notification)"
                >
                  <i
                    :class="
                      isExpanded(notification)
                        ? 'fa-duotone fa-chevron-up'
                        : 'fa-duotone fa-chevron-down'
                    "
                  />
                </Btn>
                <Btn
                  v-if="notification.link"
                  v-tooltip="t('actions.open')"
                  :to="notification.link"
                >
                  <i class="fa-duotone fa-arrow-up-right-from-square" />
                </Btn>
                <Btn
                  v-if="!notification.read"
                  v-tooltip="t('actions.adminNotifications.read')"
                  @click="markRead(notification)"
                >
                  <i class="fa-duotone fa-check" />
                </Btn>
                <Btn
                  v-tooltip="t('actions.delete')"
                  :tone="BtnTonesEnum.DANGER"
                  @click="destroy(notification)"
                >
                  <i class="fa-duotone fa-trash" />
                </Btn>
              </div>
            </div>
          </Panel>
        </li>
      </TransitionGroup>
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
.admin-notifications {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 10px;
  // Matches the margin a Panel carries by itself, which the list turns off in
  // favour of its own gap - without it the bottom paginator sits flush.
  margin: 0 0 21px;
  padding: 0;
  list-style: none;
}

// Rows change place under you - marking one read sorts it out of the unread
// group - so the list slides rather than jumping. The shared `fade-list`
// classes still carry Vue 2 names, hence the local ones.
.fade-list-enter-active,
.fade-list-leave-active,
.fade-list-move {
  transition:
    opacity 200ms ease,
    transform 250ms ease;
}

.fade-list-enter-from,
.fade-list-leave-to {
  opacity: 0;
}

// Out of flow, so the rows below close the gap while it fades.
.fade-list-leave-active {
  position: absolute;
  width: 100%;
}

.admin-notification {
  display: flex;
  align-items: flex-start;
  gap: 15px;
  padding: 14px 16px;
}

.admin-notification__icon {
  flex-shrink: 0;
  margin-top: 2px;
  color: $gray-lighter;
  font-size: 1.3em;
}

.admin-notification--unread .admin-notification__icon {
  color: var(--color-primary, #{$primary});
}

.admin-notification__content {
  flex: 1;
  min-width: 0;
}

.admin-notification__title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.admin-notification--unread .admin-notification__title {
  font-weight: bold;
}

.admin-notification__count {
  color: $gray-lighter;
  font-size: 0.85em;
}

.admin-notification__meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 4px;
  color: $gray-lighter;
  font-size: 0.85em;
}

.admin-notification__actions {
  display: flex;
  flex-shrink: 0;
  gap: 5px;
}

.admin-notification__body {
  margin: 10px 0 0;
  padding: 10px 12px;
  max-height: 320px;
  overflow: auto;
  color: $text-color;
  font-size: 0.9em;
  background-color: rgba($gray-darker, 0.6);
  border-radius: $border-radius-base;
}
</style>
