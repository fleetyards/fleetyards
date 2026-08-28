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
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BulkSelectionBar from "@/shared/components/BulkSelectionBar/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import Detail from "@/admin/components/Notifications/Detail/index.vue";
import FilterForm from "@/admin/components/Notifications/FilterForm/index.vue";
import ListItem from "@/admin/components/Notifications/ListItem/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useBulkSelection } from "@/shared/composables/useBulkSelection";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useAdminNotificationFilters,
  NOTIFICATION_TAB_QUERY_KEY,
} from "@/admin/composables/useAdminNotificationFilters";
import { useAdminNotificationInvalidation } from "@/admin/composables/useAdminNotificationUpdates";
import {
  useAdminNotifications as useAdminNotificationsQuery,
  useAdminNotificationsUnreadCount,
  getAdminNotificationsQueryKey,
  readAdminNotification,
  unreadAdminNotification,
  readAllAdminNotifications,
  archiveAdminNotification,
  unarchiveAdminNotification,
  destroyAdminNotification,
  destroyAllAdminNotifications,
  readBulkAdminNotifications,
  unreadBulkAdminNotifications,
  archiveBulkAdminNotifications,
  unarchiveBulkAdminNotifications,
  destroyBulkAdminNotifications,
  type AdminNotification,
  type AdminNotificationBulkInput,
  type AdminNotificationBulkResult,
  type AdminNotificationSortEnum,
} from "@/services/fyAdminApi";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const route = useRoute();

const sorts = computed((): AdminNotificationSortEnum[] => {
  return route.query.s ? [route.query.s as AdminNotificationSortEnum] : [];
});

const oldestFirst = computed(() => route.query.s === "createdAt asc");

// The tab is not a filter: it decides which of the two lists this is, so it
// stays out of `q` and off the filter form's "a filter is active" indicator.
const archive = computed(
  () => route.query[NOTIFICATION_TAB_QUERY_KEY] === "archive",
);

const tabLink = (archived: boolean) => ({
  query: {
    ...route.query,
    [NOTIFICATION_TAB_QUERY_KEY]: archived ? "archive" : undefined,
    // Page 4 of the inbox says nothing about the archive.
    page: undefined,
  },
});

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

// Everything in the route that `useFilters` did not recognise counts as a
// filter, so the tab has to be taken back out: left in it reaches the API as
// `q[t]`, which the query schema rejects.
const filterParams = computed(() => {
  const params: Record<string, unknown> = { ...filters.value };

  delete params[NOTIFICATION_TAB_QUERY_KEY];

  return params;
});

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    ...filterParams.value,
    archivedAtNull: !archive.value,
    sorts: sorts.value,
  },
}));

const {
  data: notifications,
  refetch,
  ...asyncStatus
} = useAdminNotificationsQuery(queryParams);

const { invalidate, invalidateUnreadCount, patchCached } =
  useAdminNotificationInvalidation();

watch([sorts, archive], async () => {
  await refetch();
});

const { data: unreadCount } = useAdminNotificationsUnreadCount();

const records = computed(() => notifications.value?.items || []);

const totalCount = computed(
  () => notifications.value?.meta.pagination?.totalCount,
);

const {
  selectedIds,
  allMatchingSelected,
  selectedCount,
  matchingCount,
  pageSelected,
  pagePartiallySelected,
  canSelectAllMatching,
  toggle: toggleSelection,
  togglePage,
  selectAllMatching,
  clear: clearSelection,
  payload: bulkPayload,
} = useBulkSelection(records, () => queryParams.value.q, totalCount);

const selectedId = ref<string>();

const selected = computed(() =>
  records.value.find((record) => record.id === selectedId.value),
);

// A deletion, a filter or another page takes the open notification with it.
watch(records, () => {
  if (selectedId.value && !selected.value) {
    selectedId.value = undefined;
  }
});

type FocusableRow = { focus: () => void };

const rows = new Map<string, FocusableRow>();

const registerRow = (notification: AdminNotification) => (row: unknown) => {
  if (row) {
    rows.set(notification.id, row as FocusableRow);
  } else {
    rows.delete(notification.id);
  }
};

const markRead = async (notification: AdminNotification) => {
  try {
    patchCached(await readAdminNotification(notification.id));
    invalidateUnreadCount();
  } catch {
    displayAlert({ text: t("messages.adminNotifications.error") });
  }
};

// Opening a notification is what reading it means, so it costs no second click.
const select = (notification: AdminNotification) => {
  selectedId.value = notification.id;

  if (!notification.read) {
    void markRead(notification);
  }
};

const move = (offset: number) => {
  const current = records.value.findIndex(
    (record) => record.id === selectedId.value,
  );

  const next = records.value[current + offset];

  if (!next) {
    return;
  }

  select(next);

  void nextTick(() => rows.get(next.id)?.focus());
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

// Closes the reading pane: leaving it open on a notification that is now unread
// invites a click that would only mark it read again, and the point of marking
// it unread is to come back to it later.
const markUnread = async (notification: AdminNotification) => {
  selectedId.value = undefined;

  await withFeedback(
    () => unreadAdminNotification(notification.id),
    t("messages.adminNotifications.unread"),
  );
};

const archiveNotification = (notification: AdminNotification) =>
  withFeedback(
    () => archiveAdminNotification(notification.id),
    t("messages.adminNotifications.archived"),
  );

const unarchiveNotification = (notification: AdminNotification) =>
  withFeedback(
    () => unarchiveAdminNotification(notification.id),
    t("messages.adminNotifications.unarchived"),
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

// The selection is spent once the action lands: leaving it ticked invites a
// second run over rows that have already moved on, and after "all matching"
// it would no longer mean the same set.
const withBulkFeedback = async (
  action: (
    input: AdminNotificationBulkInput,
  ) => Promise<AdminNotificationBulkResult>,
  key: string,
) => {
  try {
    const { count } = await action(bulkPayload.value);

    clearSelection();
    invalidate();
    displaySuccess({ text: t(key, { count }) });
  } catch {
    displayAlert({ text: t("messages.adminNotifications.error") });
  }
};

const readSelected = () =>
  withBulkFeedback(
    readBulkAdminNotifications,
    "messages.adminNotifications.bulk.read",
  );

// Same reason the single-record one closes the pane: an unread notification
// left open only invites the click that marks it read again.
const unreadSelected = () => {
  selectedId.value = undefined;

  return withBulkFeedback(
    unreadBulkAdminNotifications,
    "messages.adminNotifications.bulk.unread",
  );
};

const archiveSelected = () =>
  withBulkFeedback(
    archiveBulkAdminNotifications,
    "messages.adminNotifications.bulk.archived",
  );

const unarchiveSelected = () =>
  withBulkFeedback(
    unarchiveBulkAdminNotifications,
    "messages.adminNotifications.bulk.unarchived",
  );

const destroySelected = () =>
  withBulkFeedback(
    destroyBulkAdminNotifications,
    "messages.adminNotifications.bulk.destroyed",
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
    :records="records"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #actions-left>
      <BtnGroup segmented>
        <Btn
          :to="tabLink(false)"
          :active="!archive"
          route-active-class=""
          mobile-icon-only
          data-test="notifications-tab-inbox"
        >
          <i class="fa-duotone fa-inbox" />
          {{ t("labels.adminNotifications.inbox") }}
          <span v-if="unreadCount?.count" class="admin-notifications__badge">
            {{ unreadCount.count }}
          </span>
        </Btn>
        <Btn
          :to="tabLink(true)"
          :active="archive"
          route-active-class=""
          mobile-icon-only
          data-test="notifications-tab-archive"
        >
          <i class="fa-duotone fa-box-archive" />
          {{ t("labels.adminNotifications.archive") }}
        </Btn>
      </BtnGroup>
      <Btn :to="sortLink" route-active-class="" mobile-icon-only>
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
    <template #default="{ records: shown }">
      <BulkSelectionBar
        class="admin-notifications__bulk"
        :class="{ 'admin-notifications__bulk--hidden': !!selected }"
        :selected-count="selectedCount"
        :matching-count="matchingCount"
        :page-selected="pageSelected"
        :page-partially-selected="pagePartiallySelected"
        :can-select-all-matching="canSelectAllMatching"
        :all-matching-selected="allMatchingSelected"
        @toggle-page="togglePage"
        @select-all-matching="selectAllMatching"
        @clear="clearSelection"
      >
        <Btn
          v-tooltip="t('actions.adminNotifications.readSelected')"
          :aria-label="t('actions.adminNotifications.readSelected')"
          data-test="bulk-read"
          @click="readSelected"
        >
          <i class="fa-duotone fa-envelope-open" />
        </Btn>
        <Btn
          v-tooltip="t('actions.adminNotifications.unreadSelected')"
          :aria-label="t('actions.adminNotifications.unreadSelected')"
          data-test="bulk-unread"
          @click="unreadSelected"
        >
          <i class="fa-duotone fa-envelope-dot" />
        </Btn>
        <Btn
          v-if="archive"
          v-tooltip="t('actions.adminNotifications.unarchiveSelected')"
          :aria-label="t('actions.adminNotifications.unarchiveSelected')"
          data-test="bulk-unarchive"
          @click="unarchiveSelected"
        >
          <i class="fa-duotone fa-inbox-in" />
        </Btn>
        <Btn
          v-else
          v-tooltip="t('actions.adminNotifications.archiveSelected')"
          :aria-label="t('actions.adminNotifications.archiveSelected')"
          data-test="bulk-archive"
          @click="archiveSelected"
        >
          <i class="fa-duotone fa-box-archive" />
        </Btn>
        <Btn
          v-tooltip="t('actions.adminNotifications.destroySelected')"
          :aria-label="t('actions.adminNotifications.destroySelected')"
          :tone="BtnTonesEnum.DANGER"
          :confirm="
            t('messages.confirm.adminNotifications.destroySelected', {
              count: selectedCount,
            })
          "
          data-test="bulk-destroy"
          @click="destroySelected"
        >
          <i class="fa-duotone fa-trash" />
        </Btn>
      </BulkSelectionBar>

      <div
        class="admin-notifications"
        :class="{ 'admin-notifications--reading': !!selected }"
      >
        <TransitionGroup
          tag="ul"
          name="fade-list"
          class="admin-notifications__list"
        >
          <li
            v-for="notification in shown"
            :key="notification.id"
            class="fade-list-item"
          >
            <ListItem
              :ref="registerRow(notification)"
              :notification="notification"
              :selected="notification.id === selectedId"
              :checked="
                allMatchingSelected || selectedIds.includes(notification.id)
              "
              selectable
              @toggle="toggleSelection(notification.id)"
              @select="select(notification)"
              @archive="archiveNotification(notification)"
              @unarchive="unarchiveNotification(notification)"
              @destroy="destroy(notification)"
              @previous="move(-1)"
              @next="move(1)"
            />
          </li>
        </TransitionGroup>

        <Detail
          class="admin-notifications__detail"
          :notification="selected"
          @close="selectedId = undefined"
          @unread="selected && markUnread(selected)"
          @archive="selected && archiveNotification(selected)"
          @unarchive="selected && unarchiveNotification(selected)"
          @destroy="selected && destroy(selected)"
        />
      </div>
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
.admin-notifications__badge {
  // Round on a single digit rather than a squashed oval: the width floor and
  // the height are the same number, so it only stretches from two digits on.
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  color: $gray-black;
  // Absolute rather than an em: `mobile-icon-only` collapses the label by
  // setting the button's font-size to 0, and the count would go with it.
  font-size: 12px;
  font-weight: bold;
  line-height: 1;
  background-color: var(--color-primary, #{$primary});
  border-radius: 10px;
}

.admin-notifications__bulk {
  margin-bottom: 10px;
}

// Below the two-pane breakpoint the reading pane replaces the list, and a
// selection toolbar over a hidden list has nothing to act on.
.admin-notifications__bulk--hidden {
  display: none;
}

@media (min-width: $notifications-two-pane-breakpoint) {
  .admin-notifications__bulk--hidden {
    display: flex;
  }
}

.admin-notifications {
  display: flex;
  align-items: flex-start;
  gap: 20px;
  // Matches the margin a Panel carries by itself, which the list turns off in
  // favour of its own gap - without it the bottom paginator sits flush.
  margin: 0 0 21px;
}

.admin-notifications__list {
  position: relative;
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 10px;
  min-width: 0;
  margin: 0;
  padding: 0;
  list-style: none;
}

.admin-notifications__detail {
  display: none;
}

// One pane at a time until there is room for both: opening a notification
// replaces the list, and the reading pane brings its own way back.
.admin-notifications--reading {
  .admin-notifications__list {
    display: none;
  }

  .admin-notifications__detail {
    display: block;
    flex: 1;
    min-width: 0;
  }
}

@media (min-width: $notifications-two-pane-breakpoint) {
  .admin-notifications,
  .admin-notifications--reading {
    .admin-notifications__list {
      display: flex;
      flex: 0 0 38%;
      max-width: 38%;
    }

    .admin-notifications__detail {
      display: block;
      position: sticky;
      top: 20px;
      flex: 1;
      min-width: 0;
    }
  }
}

// Rows change place under you - a new notification arrives at the top, a
// deleted one leaves a gap - so the list slides rather than jumping. The shared
// `fade-list` classes still carry Vue 2 names, hence the local ones.
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
</style>
