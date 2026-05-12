<script lang="ts">
export default {
  name: "FleetEventPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
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
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
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
const comlink = useComlink();
const route = useRoute();
const session = useSessionStore();

const fleetSlug = computed(() => props.fleet.slug);
const eventSlug = computed(() => route.params.event as string);

const { data: event, refetch } = useFleetEvent(fleetSlug, eventSlug);

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

const unassignedSignups = computed(
  () =>
    (event.value as { unassignedSignups?: FleetEventSignup[] } | undefined)
      ?.unassignedSignups ?? [],
);

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
    <Panel class="event-hero">
      <div
        class="event-hero__inner"
        :style="cover ? { backgroundImage: `url(${cover})` } : undefined"
      >
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
        </div>
      </div>
      <div v-if="hasOverviewContent" class="event-hero__overview">
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
.event-hero__inner {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  min-height: 220px;
  padding: 1.25rem 1.5rem;
  background-color: rgba(0, 0, 0, 0.4);
  background-size: cover;
  background-position: center;
  border-top-left-radius: $panelContentBorderRadius;
  border-top-right-radius: $panelContentBorderRadius;

  &::before {
    content: "";
    position: absolute;
    inset: 0;
    border-radius: inherit;
    background: linear-gradient(
      to right,
      rgba(0, 0, 0, 0.85) 0%,
      rgba(0, 0, 0, 0.55) 40%,
      rgba(0, 0, 0, 0) 100%
    );
    pointer-events: none;
  }

  > * {
    position: relative;
    z-index: 1;
  }
}
.event-hero__tz {
  font-size: 0.85em;
  opacity: 0.75;
}
.event-hero__meta {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  margin-top: 0.5rem;
  color: rgba(255, 255, 255, 0.92);
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.85);

  p {
    margin: 0;
  }

  i {
    margin-right: 0.35rem;
    opacity: 0.9;
  }
}
.event-hero__overview {
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
.small {
  font-size: 0.8rem;
}
</style>
