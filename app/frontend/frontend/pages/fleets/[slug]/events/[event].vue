<script lang="ts">
export default {
  name: "FleetEventPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { useEventStatus } from "@/frontend/composables/useEventStatus";
import EventSlotRow from "@/frontend/components/Fleets/Events/EventSlotRow/index.vue";
import EventShipMeta from "@/frontend/components/Fleets/Events/EventShipMeta/index.vue";
import EventShipMatchWarning from "@/frontend/components/Fleets/Events/EventShipMatchWarning/index.vue";
import EventSignupCta from "@/frontend/components/Fleets/Events/EventSignupCta/index.vue";
import EventAdminActions from "@/frontend/components/Fleets/Events/EventAdminActions/index.vue";
import UnassignedSignups from "@/frontend/components/Fleets/Events/UnassignedSignups/index.vue";
import YourSignupPanel from "@/frontend/components/Fleets/Events/YourSignupPanel/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetEventTeam,
  type FleetEventShip,
  type FleetEventSlot,
  type FleetEventSignup,
  useFleetEvent,
  useSkipFleetEventOccurrence,
  useEndFleetEventSeries,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { checkAccess } from "@/shared/utils/Access";
import { format, parseISO } from "date-fns";
import { useSessionStore } from "@/frontend/stores/session";
import { useFleetEventListContextStore } from "@/frontend/stores/fleetEventListContext";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();
const route = useRoute();
const session = useSessionStore();

const fleetSlug = computed(() => props.fleet.slug);
const eventSlug = computed(() => route.params.event as string);
const occurrenceParam = computed(
  () => (route.query.occurrence as string | undefined) ?? undefined,
);

const fleetEventParams = computed(() =>
  occurrenceParam.value ? { occurrence: occurrenceParam.value } : {},
);

const { data: event, refetch } = useFleetEvent(
  fleetSlug,
  eventSlug,
  fleetEventParams as never,
);

const listContext = useFleetEventListContextStore();

const stepperList = computed<string[]>(() =>
  listContext.slugsFor(fleetSlug.value),
);

const { resolve } = useMissionCover();
const cover = computed(() => resolve(event.value));

const { toneFor, labelKeyFor } = useEventStatus();
const statusTone = computed(() =>
  event.value ? toneFor(event.value.status, event.value.past) : undefined,
);
const statusLabel = computed(() =>
  event.value ? t(labelKeyFor(event.value.status, event.value.past)) : "",
);

const canManage = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:update",
  ]),
);

const viewerEventRole = computed(
  () =>
    (event.value as { viewerEventRole?: string | null } | undefined)
      ?.viewerEventRole ?? null,
);

// Two different policies, so two different gates. FleetEventPolicy#update?
// admits the creator and per-event admins; FleetEventSignupPolicy goes through
// event_moderator_or_admin?, which is what a moderator role is actually for.
const canManageEvent = computed(() => {
  if (canManage.value) return true;
  return ["creator", "admin"].includes(viewerEventRole.value ?? "");
});

const canManageSignups = computed(() => {
  if (canManageEvent.value) return true;
  return viewerEventRole.value === "moderator";
});

const currentUserId = computed(() => session.currentUser?.id);

type SlotContext = {
  slot: FleetEventSlot;
  teamTitle: string;
  shipTitle?: string;
  ship?: FleetEventShip | null;
};

const allSlotsWithContext = computed<SlotContext[]>(() => {
  if (!event.value?.teams) return [];
  const out: SlotContext[] = [];
  for (const team of event.value.teams as FleetEventTeam[]) {
    for (const slot of (team.slots ?? []) as FleetEventSlot[]) {
      out.push({ slot, teamTitle: team.title, ship: null });
    }
    for (const ship of (team.ships ?? []) as FleetEventShip[]) {
      const shipTitle = ship.displayTitle || ship.title || undefined;
      for (const slot of (ship.slots ?? []) as FleetEventSlot[]) {
        out.push({
          slot,
          teamTitle: team.title,
          shipTitle: shipTitle ?? undefined,
          ship,
        });
      }
    }
  }
  return out;
});

const ownSignupContext = computed<{
  signup: FleetEventSignup;
  context: SlotContext | null;
} | null>(() => {
  const userId = currentUserId.value;
  if (!userId) return null;
  for (const ctx of allSlotsWithContext.value) {
    const signup = (ctx.slot.signups ?? []).find((s) => s.user?.id === userId);
    if (signup) return { signup, context: ctx };
  }
  const eventLevel = (
    (event.value as { unassignedSignups?: FleetEventSignup[] } | undefined)
      ?.unassignedSignups ?? []
  ).find((s) => s.user?.id === userId);
  if (eventLevel) return { signup: eventLevel, context: null };
  return null;
});

const canSignupToEvent = computed(
  () =>
    !!event.value &&
    event.value.signupsOpen &&
    !!checkAccess(props.resourceAccess, [
      "fleet:manage",
      "fleet:events:manage",
      "fleet:events:read",
    ]),
);

const ownActiveSlotId = computed(
  () => ownSignupContext.value?.context?.slot.id ?? null,
);

const yourSignupSlotTitle = computed(() => {
  const ctx = ownSignupContext.value?.context;
  if (!ctx) return t("labels.fleets.events.noSlotYet");
  return ctx.slot.title;
});

const yourSignupContextLabel = computed(() => {
  const ctx = ownSignupContext.value?.context;
  if (!ctx) return undefined;
  const parts = [ctx.teamTitle];
  if (ctx.shipTitle) parts.push(ctx.shipTitle);
  return parts.join(" · ");
});

const startDate = computed(() => {
  if (!event.value) return "";
  try {
    return format(parseISO(event.value.startsAt), "EEE, MMM d, yyyy · HH:mm");
  } catch {
    return event.value.startsAt;
  }
});

const endDate = computed(() => {
  if (!event.value?.endsAt) return null;
  try {
    return format(parseISO(event.value.endsAt), "EEE, MMM d, yyyy · HH:mm");
  } catch {
    return event.value.endsAt;
  }
});

const signupsLocked = computed(
  () =>
    !event.value ||
    ["draft", "locked", "active", "completed", "cancelled"].includes(
      event.value.status,
    ),
);

const signupsOpenForEvent = computed(() => !!event.value?.signupsOpen);

const hasOverviewContent = computed(
  () => !!(event.value?.description || event.value?.briefing),
);

const icsDownloadUrl = computed(() => {
  if (!event.value) return undefined;
  return `${window.API_ENDPOINT}/fleets/${props.fleet.slug}/events/${event.value.slug}/event.ics`;
});

const unassignedSignups = computed(
  () =>
    (event.value as { unassignedSignups?: FleetEventSignup[] } | undefined)
      ?.unassignedSignups ?? [],
);

const isRecurring = computed(() => event.value?.recurring === true);

const intervalLabel = computed(() => {
  const interval = event.value?.recurrenceInterval as string | undefined;
  if (!interval) return "";
  return t(`labels.fleets.events.recurrence.${interval}`);
});

const recurringChip = computed(() => {
  if (!isRecurring.value) return "";
  const interval = intervalLabel.value || t("labels.fleets.events.recurring");
  if (event.value?.recurrenceUntil) {
    return t("labels.fleets.events.recurringUntil", {
      interval,
      date: event.value.recurrenceUntil,
    });
  }
  if (event.value?.recurrenceCount) {
    return t("labels.fleets.events.recurringForCount", {
      interval,
      count: event.value.recurrenceCount,
    });
  }
  return t("labels.fleets.events.recurringSummary", { interval });
});

const excludedDateSet = computed(() => {
  const dates = (event.value?.excludedDates ?? []) as string[];
  return new Set(dates);
});

const advanceDate = (date: Date, interval: string): Date => {
  const next = new Date(date);
  switch (interval) {
    case "daily":
      next.setDate(next.getDate() + 1);
      break;
    case "weekly":
      next.setDate(next.getDate() + 7);
      break;
    case "biweekly":
      next.setDate(next.getDate() + 14);
      break;
    case "monthly":
      next.setMonth(next.getMonth() + 1);
      break;
  }
  return next;
};

const isoDate = (date: Date): string => date.toISOString().slice(0, 10);

const upcomingOccurrences = computed(() => {
  if (!isRecurring.value || !event.value?.startsAt) return [];
  const interval = event.value.recurrenceInterval as string | undefined;
  if (!interval) return [];

  const start = new Date(event.value.startsAt);
  const until = event.value.recurrenceUntil
    ? new Date(`${event.value.recurrenceUntil}T23:59:59Z`)
    : null;
  const max = event.value.recurrenceCount ?? null;
  const now = new Date();
  const horizon = new Date(now.getTime() + 12 * 7 * 24 * 60 * 60 * 1000);

  const result: { date: string; iso: string; excluded: boolean }[] = [];
  let cursor = new Date(start);
  let i = 0;
  while (cursor <= horizon && (max === null || i < max)) {
    if (until && cursor > until) break;
    if (cursor >= now) {
      const iso = isoDate(cursor);
      result.push({
        date: cursor.toLocaleDateString(undefined, {
          weekday: "short",
          month: "short",
          day: "numeric",
          year: "numeric",
        }),
        iso,
        excluded: excludedDateSet.value.has(iso),
      });
    }
    cursor = advanceDate(cursor, interval);
    i += 1;
    if (result.length >= 12) break;
  }
  return result;
});

const skipMutation = useSkipFleetEventOccurrence();
const endMutation = useEndFleetEventSeries();

const skipOccurrence = async (iso: string) => {
  if (!event.value) return;
  try {
    await skipMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: event.value.slug,
      data: { date: iso } as never,
    });
    await refetch();
    displaySuccess({
      text: t("labels.fleets.events.skipOccurrenceSuccess"),
    });
  } catch {
    displayAlert({ text: t("messages.fleets.event.update.failure") });
  }
};

const overrideOccurrence = (iso: string) => {
  if (!event.value) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventOccurrenceOverrideModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: event.value,
      occurrenceDate: iso,
    },
  });
};

const endSeriesAt = (iso: string) => {
  if (!event.value) return;
  displayConfirm({
    text: t("labels.fleets.events.endSeriesConfirm"),
    onConfirm: async () => {
      try {
        await endMutation.mutateAsync({
          fleetSlug: props.fleet.slug,
          slug: event.value!.slug,
          data: { date: iso } as never,
        });
        await refetch();
        displaySuccess({
          text: t("labels.fleets.events.endSeriesSuccess"),
        });
      } catch {
        displayAlert({ text: t("messages.fleets.event.update.failure") });
      }
    },
  });
};

const fleetEventUpdatedComlink = ref<() => void>();
const fleetEventSignupChangedComlink = ref<() => void>();
const fleetEventChildrenChangedComlink = ref<() => void>();

onMounted(() => {
  fleetEventUpdatedComlink.value = comlink.on(
    "fleet-event-updated",
    () => void refetch(),
  );
  fleetEventSignupChangedComlink.value = comlink.on(
    "fleet-event-signup-changed",
    () => void refetch(),
  );
  fleetEventChildrenChangedComlink.value = comlink.on(
    "fleet-event-children-changed",
    () => void refetch(),
  );
});

onUnmounted(() => {
  fleetEventUpdatedComlink.value?.();
  fleetEventSignupChangedComlink.value?.();
  fleetEventChildrenChangedComlink.value?.();
});

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-events", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.events.index"),
  },
]);
</script>

<template>
  <BreadCrumbs
    :crumbs="crumbs"
    :current-id="eventSlug"
    :stepper-list="stepperList"
    stepper-route="fleet-event"
    stepper-param="event"
    :stepper-extra-params="{ slug: fleet.slug }"
  >
    <template v-if="canManageEvent && event" #actions>
      <EventAdminActions
        :fleet="fleet"
        :event="event"
        :resource-access="resourceAccess"
      />
    </template>
  </BreadCrumbs>

  <div v-if="event" class="event-detail">
    <Panel :bg-image="cover" :tone="statusTone" class="event-detail__hero">
      <PanelHeading :shadow="PanelHeadingShadowEnum.TOP">
        <template #default>
          {{ event.title }}
        </template>
        <template #actions>
          <!-- Framed: bare is for a chip inside something already interactive,
               which the hero is not, and without the frame the status read as
               plain text sitting on the cover. -->
          <Chip>{{ statusLabel }}</Chip>
        </template>
      </PanelHeading>

      <!--
        Below the cover, not on it. The scrim PanelHeading draws covers a
        heading; it was never going to carry eight lines of metadata, which is
        what the removed bg-overlay was really doing.
      -->
      <template #footer>
        <PanelBody>
          <div class="metrics-card__rows metrics-card__rows--split">
            <div class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t("labels.fleets.events.startsAt") }}
              </div>
              <div class="metrics-card__row__value">
                {{ startDate }}
                <template v-if="endDate"> — {{ endDate }}</template>
                <span v-if="event.timezone" class="event-hero__tz">
                  ({{ event.timezone }})
                </span>
              </div>
            </div>
            <div v-if="recurringChip" class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t("labels.fleets.events.repeats") }}
              </div>
              <div class="metrics-card__row__value">
                {{ recurringChip }}
                <router-link
                  v-if="occurrenceParam"
                  :to="{
                    name: 'fleet-event',
                    params: { slug: fleet.slug, event: eventSlug },
                  }"
                  class="event-hero__series-link"
                >
                  {{ t("labels.fleets.events.viewSeries") }}
                </router-link>
              </div>
            </div>
            <div v-if="event.location" class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t("labels.fleets.events.location") }}
              </div>
              <div class="metrics-card__row__value">{{ event.location }}</div>
            </div>
            <div v-if="event.meetupLocation" class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t("labels.fleets.events.meetupLocation") }}
              </div>
              <div class="metrics-card__row__value">
                {{ event.meetupLocation }}
              </div>
            </div>
            <div v-if="event.category" class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t("labels.fleets.missions.category") }}
              </div>
              <div class="metrics-card__row__value">
                {{ t(`labels.fleets.missions.categories.${event.category}`) }}
                <template v-if="event.scenario">
                  · {{ event.scenario }}
                </template>
              </div>
            </div>
            <div v-if="event.visibility" class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t("labels.fleets.events.visibility") }}
              </div>
              <div class="metrics-card__row__value">
                {{ t(`labels.fleets.events.visibilities.${event.visibility}`) }}
              </div>
            </div>
            <div v-if="event.maxAttendees" class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t("labels.fleets.events.maxAttendees") }}
              </div>
              <div class="metrics-card__row__value">
                {{ event.maxAttendees }}
              </div>
            </div>
          </div>

          <div v-if="icsDownloadUrl" class="event-hero__actions">
            <Btn :href="icsDownloadUrl" variant="bare">
              <i class="fa-light fa-calendar-arrow-down" />
              {{ t("actions.fleets.events.addToCalendar") }}
            </Btn>
          </div>

          <div v-if="hasOverviewContent" class="event-overview">
            <p v-if="event.description" class="event-description">
              {{ event.description }}
            </p>
            <details v-if="event.briefing" class="event-briefing">
              <summary>{{ t("labels.fleets.events.briefing") }}</summary>
              <p>{{ event.briefing }}</p>
            </details>
          </div>
        </PanelBody>
      </template>
    </Panel>

    <YourSignupPanel
      v-if="ownSignupContext"
      :signup="ownSignupContext.signup"
      :slot-title="yourSignupSlotTitle"
      :context-label="yourSignupContextLabel"
      :ship="ownSignupContext.context?.ship"
      :fleet-slug="fleet.slug"
      :event-slug="event.slug"
    />
    <EventSignupCta
      v-else-if="canSignupToEvent"
      :fleet-slug="fleet.slug"
      :event="event"
      :signups-locked="signupsLocked"
    />

    <UnassignedSignups
      v-if="canManageSignups && unassignedSignups.length"
      :fleet="fleet"
      :event="event"
      :signups="unassignedSignups"
    />

    <section v-if="isRecurring" class="event-occurrences">
      <Heading size="lg">
        {{ t("labels.fleets.events.occurrencesSection") }}
      </Heading>
      <p v-if="!upcomingOccurrences.length" class="text-muted small">
        {{ t("labels.fleets.events.noUpcomingOccurrences") }}
      </p>
      <ul v-else class="event-occurrences__list">
        <li
          v-for="entry in upcomingOccurrences"
          :key="entry.iso"
          class="event-occurrences__item"
          :class="{ 'event-occurrences__item--excluded': entry.excluded }"
        >
          <span class="event-occurrences__date">
            <i class="fa-light fa-calendar" />
            {{ entry.date }}
          </span>
          <span v-if="entry.excluded" class="event-occurrences__badge">
            {{ t("labels.fleets.events.excludedBadge") }}
          </span>
          <div v-if="canManageEvent" class="event-occurrences__actions">
            <button
              v-if="!entry.excluded"
              type="button"
              class="event-occurrences__btn"
              @click="overrideOccurrence(entry.iso)"
            >
              <i class="fa-light fa-pen" />
              {{ t("labels.fleets.events.overrideOccurrenceShort") }}
            </button>
            <button
              v-if="!entry.excluded"
              type="button"
              class="event-occurrences__btn"
              @click="skipOccurrence(entry.iso)"
            >
              <i class="fa-light fa-ban" />
              {{ t("labels.fleets.events.skipOccurrence") }}
            </button>
            <button
              type="button"
              class="event-occurrences__btn"
              @click="endSeriesAt(entry.iso)"
            >
              <i class="fa-light fa-flag-checkered" />
              {{ t("labels.fleets.events.endSeriesHere") }}
            </button>
          </div>
        </li>
      </ul>
    </section>

    <section v-if="event.teams?.length" class="event-teams">
      <Heading size="lg">
        {{ t("headlines.fleets.events.schedule") }}
      </Heading>

      <p v-if="signupsLocked" class="text-muted small">
        <i class="fa-light fa-lock" />
        {{ t("labels.fleets.events.signupsLockedHint") }}
      </p>

      <div
        v-for="team in event.teams as FleetEventTeam[]"
        :key="team.id"
        class="event-team"
      >
        <h3 class="event-team__title">{{ team.title }}</h3>
        <p v-if="team.description" class="text-muted">{{ team.description }}</p>

        <div v-if="team.slots?.length" class="event-slots">
          <EventSlotRow
            v-for="slot in team.slots as FleetEventSlot[]"
            :key="slot.id"
            :slot-data="slot"
            :fleet="fleet"
            :event="event"
            :current-user-id="currentUserId"
            :signups-locked="signupsLocked"
            :signups-open="signupsOpenForEvent"
            :own-active-slot-id="ownActiveSlotId"
            :is-manager="canManageSignups"
          />
        </div>

        <div v-if="team.ships?.length" class="event-ships">
          <div
            v-for="ship in team.ships as FleetEventShip[]"
            :key="ship.id"
            class="event-ship"
          >
            <h4 class="event-ship__title">
              {{ ship.displayTitle || ship.title || "Ship" }}
            </h4>
            <p v-if="ship.description" class="text-muted small">
              {{ ship.description }}
            </p>
            <EventShipMeta :ship="ship" />
            <EventShipMatchWarning :ship="ship" />
            <div class="event-slots">
              <EventSlotRow
                v-for="slot in ship.slots as FleetEventSlot[]"
                :key="slot.id"
                :slot-data="slot"
                :ship="ship"
                :fleet="fleet"
                :event="event"
                :current-user-id="currentUserId"
                :signups-locked="signupsLocked"
                :signups-open="signupsOpenForEvent"
                :own-active-slot-id="ownActiveSlotId"
                :is-manager="canManageSignups"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.event-detail {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.event-detail__hero {
  --panel-image-height: 260px;
}
.event-hero__tz {
  font-size: 0.85em;
  opacity: 0.75;
}
.event-hero__series-link {
  margin-left: 8px;
}
.event-hero__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 14px;
}
.event-overview {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 18px;
}
.event-description {
  margin: 0;
  white-space: pre-wrap;
}
.event-briefing {
  background: rgb(0 0 0 / 0.2);
  border: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  border-radius: var(--radius-control-bare, 6px);
  padding: 10px 14px;

  summary {
    cursor: pointer;
    font-weight: 600;
  }
}
.event-teams {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.event-team {
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  padding-top: 16px;
}
.event-team__title {
  margin: 0 0 4px;
}
.event-slots {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 8px;
}
.event-ships {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  margin-top: 16px;
}
.event-ship {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: var(--radius-control-bare, 6px);
  padding: 12px;
}
.event-ship__title {
  margin: 0 0 8px;
  font-size: 15px;
}
.event-occurrences {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.event-occurrences__list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.event-occurrences__item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: var(--radius-control-bare, 6px);
  font-size: 14px;

  &--excluded {
    opacity: 0.55;
    text-decoration: line-through;
  }
}
.event-occurrences__date {
  flex: 1;
}
.event-occurrences__badge {
  font-size: 12px;
  padding: 2px 8px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 10px;
}
.event-occurrences__actions {
  display: flex;
  gap: 8px;
}
.event-occurrences__btn {
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: inherit;
  font-size: 13px;
  padding: 4px 8px;
  border-radius: var(--radius-control-bare, 6px);
  cursor: pointer;

  &:hover {
    background: rgba(255, 255, 255, 0.05);
  }
}
.small {
  font-size: 13px;
}
</style>
