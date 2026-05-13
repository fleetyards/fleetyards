<script lang="ts">
export default {
  name: "FleetEventPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { PanelBgOverlayDirectionEnum } from "@/shared/components/base/Panel/types";
import EventStatusBadge from "@/frontend/components/Fleets/Events/EventStatusBadge/index.vue";
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

const isEventManager = computed(() => {
  if (canManage.value) return true;
  return ["creator", "admin", "moderator"].includes(
    viewerEventRole.value ?? "",
  );
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

onMounted(() => {
  comlink.on("fleet-event-updated", () => void refetch());
  comlink.on("fleet-event-signup-changed", () => void refetch());
  comlink.on("fleet-event-children-changed", () => void refetch());
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
    <template v-if="isEventManager && event" #actions>
      <EventAdminActions
        :fleet="fleet"
        :event="event"
        :resource-access="resourceAccess"
      />
    </template>
  </BreadCrumbs>

  <div v-if="event" class="event-detail">
    <Panel
      :bg-image="cover"
      bg-overlay
      :bg-overlay-direction="PanelBgOverlayDirectionEnum.RIGHT"
    >
      <template #hero>
        <Heading size="hero" hero>
          {{ event.title }}
          <EventStatusBadge :status="event.status" :past="event.past" />
        </Heading>
        <div class="event-hero__meta">
          <p>
            <i class="fa-light fa-calendar" />
            {{ startDate }}
            <span v-if="endDate"> — {{ endDate }}</span>
            <span v-if="event.timezone" class="event-hero__tz">
              ({{ event.timezone }})
            </span>
          </p>
          <p v-if="recurringChip">
            <i class="fa-light fa-arrows-rotate" />
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
          </p>
          <p v-if="event.location">
            <i class="fa-light fa-location-dot" />
            {{ event.location }}
          </p>
          <p v-if="event.meetupLocation">
            <i class="fa-light fa-flag" />
            {{ event.meetupLocation }}
          </p>
          <p v-if="event.category">
            <i class="fa-light fa-tag" />
            {{ t(`labels.fleets.missions.categories.${event.category}`) }}
            <span v-if="event.scenario"> · {{ event.scenario }}</span>
          </p>
          <p v-if="event.visibility">
            <i class="fa-light fa-eye" />
            {{ t(`labels.fleets.events.visibilities.${event.visibility}`) }}
          </p>
          <p v-if="event.maxAttendees">
            <i class="fa-light fa-users" />
            {{
              t("labels.fleets.events.maxAttendeesValue", {
                count: event.maxAttendees,
              })
            }}
          </p>
          <p>
            <a
              v-if="icsDownloadUrl"
              :href="icsDownloadUrl"
              class="event-hero__ics"
              download
            >
              <i class="fa-light fa-calendar-arrow-down" />
              {{ t("actions.fleets.events.addToCalendar") }}
            </a>
          </p>
        </div>
      </template>
      <div v-if="hasOverviewContent" class="event-overview">
        <p v-if="event.description" class="event-description">
          {{ event.description }}
        </p>
        <details v-if="event.briefing" class="event-briefing">
          <summary>{{ t("labels.fleets.events.briefing") }}</summary>
          <p>{{ event.briefing }}</p>
        </details>
      </div>
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
      v-if="isEventManager && unassignedSignups.length"
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
          <div v-if="isEventManager" class="event-occurrences__actions">
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
            :is-manager="isEventManager"
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
                :is-manager="isEventManager"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.event-detail {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.event-hero__tz {
  font-size: 0.85em;
  opacity: 0.75;
}
.event-hero__ics {
  color: inherit;
  text-decoration: underline;
  text-underline-offset: 2px;

  &:hover {
    opacity: 0.85;
  }
}
.event-hero__meta {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  margin-top: 0.5rem;

  p {
    margin: 0;
  }

  i {
    margin-right: 0.35rem;
    opacity: 0.9;
  }
}
.event-overview {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1rem 1.5rem 1.25rem;
}
.event-description {
  margin: 0;
  white-space: pre-wrap;
}
.event-briefing {
  background: rgba(255, 255, 255, 0.03);
  border-radius: 4px;
  padding: 0.5rem 1rem;

  summary {
    cursor: pointer;
    font-weight: 600;
  }
}
.event-teams {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.event-team {
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  padding-top: 1rem;
}
.event-team__title {
  margin: 0 0 0.25rem;
}
.event-slots {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-top: 0.5rem;
}
.event-ships {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}
.event-ship {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 4px;
  padding: 0.75rem;
}
.event-ship__title {
  margin: 0 0 0.5rem;
  font-size: 0.95rem;
}
.event-occurrences {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.event-occurrences__list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.event-occurrences__item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 0.75rem;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 4px;
  font-size: 0.9rem;

  &--excluded {
    opacity: 0.55;
    text-decoration: line-through;
  }
}
.event-occurrences__date {
  flex: 1;
}
.event-occurrences__badge {
  font-size: 0.75rem;
  padding: 0.15rem 0.5rem;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 10px;
}
.event-occurrences__actions {
  display: flex;
  gap: 0.5rem;
}
.event-occurrences__btn {
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: inherit;
  font-size: 0.8rem;
  padding: 0.2rem 0.5rem;
  border-radius: 3px;
  cursor: pointer;

  &:hover {
    background: rgba(255, 255, 255, 0.05);
  }
}
.small {
  font-size: 0.8rem;
}
</style>
