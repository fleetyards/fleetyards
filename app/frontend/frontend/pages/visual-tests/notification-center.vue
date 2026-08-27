<script lang="ts">
export default {
  name: "VisualTestsNotificationCenterPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import NotificationsListItem from "@/frontend/components/Notifications/ListItem/index.vue";
import NotificationsDetail from "@/frontend/components/Notifications/Detail/index.vue";
import { NotificationTypeEnum, type Notification } from "@/services/fyApi";

/*
 * The centre's two halves, driven by props rather than by the page's queries.
 * Everything worth looking at here is a state the real page reaches only when
 * the data happens to be in it: unread next to read, an archived row, a body
 * long enough to test the reading pane, a title with nothing to break on, and
 * no selection at all.
 */
const at = (iso: string) => iso;

const base = {
  notificationType: NotificationTypeEnum.HANGAR_CREATE,
  read: false,
  archived: false,
  expiresAt: at("2029-07-14T19:30:00.000Z"),
  createdAt: at("2029-06-14T19:30:00.000Z"),
  updatedAt: at("2029-06-14T19:30:00.000Z"),
};

const notification = (
  overrides: Partial<Notification> & { id: string; title: string },
): Notification => ({ ...base, ...overrides }) as Notification;

const unread = notification({
  id: "unread",
  title: "You were invited to Blue Sun Logistics",
  notificationType: NotificationTypeEnum.FLEET_INVITE,
  icon: "fa-duotone fa-users",
  body: "Accept the invite to see the fleet's hangar and events.",
  link: "/fleets",
});

// Read, so the list has something to contrast the unread ones against.
const read = notification({
  id: "read",
  title: "Carrack added to your wishlist",
  notificationType: NotificationTypeEnum.WISHLIST_CREATE,
  icon: "fa-duotone fa-heart",
  read: true,
  readAt: at("2029-06-14T20:00:00.000Z"),
});

// No body at all, which is the common case for the hangar and wishlist types
// and the one the reading pane needs a placeholder for.
const bodyless = notification({
  id: "bodyless",
  title: "Aurora MR added to your hangar",
  icon: "fa-duotone fa-warehouse",
});

const failure = notification({
  id: "failure",
  title: "Hangar sync failed",
  notificationType: NotificationTypeEnum.HANGAR_SYNC_FAILED,
  icon: "fa-duotone fa-rotate-exclamation",
  body: "The RSI website did not answer in time. Nothing was imported.",
  link: "/hangar",
});

const archived = notification({
  id: "archived",
  title: "Hangar sync finished",
  notificationType: NotificationTypeEnum.HANGAR_SYNC_FINISHED,
  icon: "fa-duotone fa-rotate",
  read: true,
  readAt: at("2029-06-13T09:00:00.000Z"),
  archived: true,
  archivedAt: at("2029-06-13T09:00:00.000Z"),
  body: "18 ships imported, 2 updated.",
});

const longTitle = notification({
  id: "long",
  title:
    "Origin 890 Jump Midsummer Nights Dream Edition was added to your hangar as rsi-origin-890-jump-midsummer",
  icon: "fa-duotone fa-warehouse",
});

// The body is markdown, so a fleet event notification arrives with headings and
// lists in it.
const longBody = notification({
  id: "long-body",
  title: "Mining Run starts in an hour",
  notificationType: NotificationTypeEnum.FLEET_EVENT_STARTING_SOON,
  icon: "fa-duotone fa-calendar-clock",
  link: "/fleets",
  body: [
    "## Mining Run",
    "",
    "Meet at **Port Olisar**, 19:00 UTC.",
    "",
    "### Bring",
    "",
    "- a Prospector, or",
    "- a Mole with a crew of three",
    "",
    "Your slot: `mole-turret-2`.",
  ].join("\n"),
});

const listed = [unread, failure, bodyless, read, longTitle, archived];

const selectedId = ref<string>(unread.id);

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
  <Heading :level="HeadingLevelEnum.H2">ListItem | Read and unread</Heading>
  <p>
    Unread is the default state, and the contrast between the two is the only
    thing telling them apart in a list of twenty — no pill, no colour.
  </p>
  <div class="vt-stack" data-test="states">
    <NotificationsListItem
      v-for="item in [unread, failure, read]"
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
    states side by side, since the difference has to read at a glance.
  </p>
  <div class="vt-stack" data-test="selection">
    <NotificationsListItem :notification="failure" />
    <NotificationsListItem :notification="failure" selected />
  </div>

  <Heading :level="HeadingLevelEnum.H2">ListItem | The awkward ones</Heading>
  <p>
    An archived row, which carries the way back to the inbox instead of the
    archive action, and a title with a generated identifier in it that has
    nothing to break on.
  </p>
  <div class="vt-stack" data-test="awkward">
    <NotificationsListItem :notification="archived" />
    <NotificationsListItem :notification="longTitle" />
  </div>

  <Heading :level="HeadingLevelEnum.H2">Detail | With a notification</Heading>
  <p>
    The reading pane. Its body is markdown, so the cases worth having are a
    short one and one with headings and lists in it.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <NotificationsDetail
        :notification="failure"
        @close="record('close')"
        @unread="record('unread')"
        @archive="record('archive')"
        @unarchive="record('unarchive')"
        @destroy="record('destroy')"
      />
    </div>
    <div class="col-12 col-lg-6">
      <NotificationsDetail :notification="longBody" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Detail | Without a body</Heading>
  <p>
    Most hangar and wishlist notifications are a title and nothing else, so the
    pane says so rather than showing an empty box.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <NotificationsDetail :notification="bodyless" />
    </div>
    <div class="col-12 col-lg-6">
      <NotificationsDetail :notification="archived" />
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
