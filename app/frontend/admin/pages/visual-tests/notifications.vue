<script lang="ts">
export default {
  name: "AdminVisualTestsNotificationsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import NotificationsListItem from "@/admin/components/Notifications/ListItem/index.vue";
import NotificationsDetail from "@/admin/components/Notifications/Detail/index.vue";
import {
  AdminNotificationSeverityEnum,
  AdminNotificationTypeEnum,
  type AdminNotification,
} from "@/services/fyAdminApi";

/*
 * The notification centre's two halves, driven by props rather than by the
 * page's queries. Everything worth looking at here is a state the real page
 * reaches only when the data happens to be in it: an error next to an info, an
 * unread next to a read, something that has occurred 47 times, a body long
 * enough to test the reading pane, and no selection at all.
 */
const at = (iso: string) => iso;

const base = {
  notificationType: AdminNotificationTypeEnum.PAINTS_IMPORT,
  occurrences: 1,
  lastOccurredAt: at("2029-06-14T19:30:00.000Z"),
  read: false,
  archived: false,
  expiresAt: at("2029-07-14T19:30:00.000Z"),
  createdAt: at("2029-06-14T19:30:00.000Z"),
  updatedAt: at("2029-06-14T19:30:00.000Z"),
};

const notification = (
  overrides: Partial<AdminNotification> & { id: string; title: string },
): AdminNotification =>
  ({
    ...base,
    severity: AdminNotificationSeverityEnum.INFO,
    ...overrides,
  }) as AdminNotification;

const info = notification({
  id: "info",
  title: "Weekly stats are ready",
  notificationType: AdminNotificationTypeEnum.WEEKLY_STATS,
  body: "1,284 ships added, 96 fleets created.",
});

const warning = notification({
  id: "warning",
  title: "Paints import finished with warnings",
  severity: AdminNotificationSeverityEnum.WARNING,
  body: "Three paints had no matching model and were skipped.",
});

const error = notification({
  id: "error",
  title: "RSI API blocked",
  severity: AdminNotificationSeverityEnum.ERROR,
  notificationType: AdminNotificationTypeEnum.RSI_API_BLOCKED,
  body: "Hangar sync is paused until the block clears.",
});

// Read, so the list has something to contrast the unread ones against.
const read = notification({
  id: "read",
  title: "Loaner sync finished",
  notificationType: AdminNotificationTypeEnum.LOANER_SYNC,
  read: true,
  readAt: at("2029-06-14T20:00:00.000Z"),
  body: "No changes.",
});

// Repeats collapse into one row with a count, which is the case that decides
// whether the title still fits.
const repeated = notification({
  id: "repeated",
  title: "UEX commodity prices import failed",
  severity: AdminNotificationSeverityEnum.ERROR,
  notificationType: AdminNotificationTypeEnum.UEX_COMMODITY_PRICES_IMPORT,
  occurrences: 47,
  body: "Timed out reaching the UEX API.",
});

const archived = notification({
  id: "archived",
  title: "Modules import finished",
  notificationType: AdminNotificationTypeEnum.MODULES_IMPORT,
  archived: true,
  archivedAt: at("2029-06-13T09:00:00.000Z"),
  read: true,
  readAt: at("2029-06-13T09:00:00.000Z"),
});

const longTitle = notification({
  id: "long",
  title:
    "Paints import finished with warnings for rsi-constellation-andromeda-paint-invictus-2949-limited-edition",
  severity: AdminNotificationSeverityEnum.WARNING,
  body: "The identifier above has nothing to break on, which is what makes it worth having here.",
});

// The body is markdown, and these are generated reports - headings, lists and
// identifiers with no spaces in them.
const longBody = notification({
  id: "long-body",
  title: "Weekly stats",
  notificationType: AdminNotificationTypeEnum.WEEKLY_STATS,
  body: [
    "# Weekly stats",
    "",
    "Ships added: **1,284**. Fleets created: **96**.",
    "",
    "## Imports",
    "",
    "- paints: 3 skipped",
    "- modules: clean",
    "- loaners: clean",
    "",
    "## Slowest job",
    "",
    "`uex_commodity_prices_import` at 4m 12s, identifier",
    "rsi-constellation-andromeda-0000000000000000000000.",
  ].join("\n"),
});

const listed = [info, warning, error, repeated, read, longTitle, archived];

const selectedId = ref<string>(info.id);

const selected = computed(() =>
  listed.find((item) => item.id === selectedId.value),
);

const log = ref<string[]>([]);

const record = (entry: string) => {
  log.value = [entry, ...log.value.filter((seen) => seen !== entry)].slice(
    0,
    6,
  );
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">ListItem | Severities</Heading>
  <p>
    The row carries the severity as a pill, and <code>info</code> carries none —
    a label on every row would say nothing. Unread is the default state; the
    read one below it is what the contrast has to survive.
  </p>
  <div class="vt-stack" data-test="severities">
    <NotificationsListItem
      v-for="item in [info, warning, error, read]"
      :key="item.id"
      :notification="item"
      @select="record(`select ${item.id}`)"
      @archive="record(`archive ${item.id}`)"
      @unarchive="record(`unarchive ${item.id}`)"
      @destroy="record(`destroy ${item.id}`)"
    />
  </div>

  <Heading :level="HeadingLevelEnum.H2">ListItem | Selected</Heading>
  <p>
    Selection is a prop, so the row does not know which pane is showing it. Both
    states side by side, since the difference has to read at a glance in a list
    of twenty.
  </p>
  <div class="vt-stack" data-test="selection">
    <NotificationsListItem :notification="error" />
    <NotificationsListItem :notification="error" selected />
  </div>

  <Heading :level="HeadingLevelEnum.H2">ListItem | The awkward ones</Heading>
  <p>
    A repeat count, an archived row, and a title with a generated identifier in
    it that has nothing to break on.
  </p>
  <div class="vt-stack" data-test="awkward">
    <NotificationsListItem :notification="repeated" />
    <NotificationsListItem :notification="archived" />
    <NotificationsListItem :notification="longTitle" />
  </div>

  <Heading :level="HeadingLevelEnum.H2">Detail | With a notification</Heading>
  <p>
    The reading pane. Its body is markdown, and these are generated reports, so
    the cases worth having are a short one and one with headings, lists and an
    unbreakable identifier.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <NotificationsDetail
        :notification="error"
        @close="record('close')"
        @unread="record('unread')"
        @archive="record('archive')"
        @unarchive="record('unarchive')"
      />
    </div>
    <div class="col-12 col-lg-6">
      <NotificationsDetail :notification="longBody" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Detail | Empty</Heading>
  <p>
    No selection. This is what the pane shows for most of the time the page is
    open, so it is the state most worth looking at and the one hardest to reach
    on the real page.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <NotificationsDetail />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">The two together</Heading>
  <p>
    List and pane, wired to each other. Below
    <code>$notifications-two-pane-breakpoint</code> the real page shows one at a
    time, which is what the narrow-viewport check is for.
  </p>
  <div class="row">
    <div class="col-12 col-lg-5">
      <div class="vt-stack" data-test="wired-list">
        <NotificationsListItem
          v-for="item in listed"
          :key="item.id"
          :notification="item"
          :selected="item.id === selectedId"
          @select="selectedId = item.id"
        />
      </div>
    </div>
    <div class="col-12 col-lg-7">
      <NotificationsDetail
        :notification="selected"
        data-test="wired-detail"
        @close="selectedId = ''"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseText muted no-spacing>Emitted:</BaseText>
      <ul data-test="emitted">
        <li v-for="entry in log" :key="entry" :data-test="`fired-${entry}`">
          {{ entry }}
        </li>
        <li v-if="!log.length">—</li>
      </ul>
    </div>
  </div>
</template>
