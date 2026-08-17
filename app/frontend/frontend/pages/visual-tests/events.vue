<script lang="ts">
export default {
  name: "VisualTestsEventsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import EventPanel from "@/frontend/components/Fleets/Events/EventPanel/index.vue";
import EventSignupCta from "@/frontend/components/Fleets/Events/EventSignupCta/index.vue";
import EventSlotRow from "@/frontend/components/Fleets/Events/EventSlotRow/index.vue";
import EventShipCard from "@/frontend/components/Fleets/Events/EventShipCard/index.vue";
import MissionPanel from "@/frontend/components/Fleets/Missions/MissionPanel/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetEventShip,
  type FleetEventSignup,
  type FleetEventSlot,
  type FleetEventTeam,
  type Mission,
  FleetEventCategory,
  FleetEventSignupApproval,
  FleetEventSignupStatus,
  FleetEventSlotEffectiveSignupApproval,
  FleetEventSlotSlottableType,
  FleetEventStatus,
  FleetEventVisibility,
  MissionCategory,
} from "@/services/fyApi";

/*
 * Fixtures rather than fetched records: this page exists to pin how the
 * surfaces render, and a seeded fleet would make every state depend on the
 * backend agreeing to produce it. The statuses in particular are the point -
 * six lifecycle tones is not something a scenario hands you for free.
 */
const NOW = "2026-09-04T19:30:00Z";

const fleet: Fleet = {
  id: "fleet-1",
  fid: "SILENTWINGS",
  name: "Silent Wings",
  slug: "silent-wings",
  publicFleet: true,
  publicFleetStats: true,
  createdAt: NOW,
  updatedAt: NOW,
};

const eventFor = (
  status: FleetEventStatus,
  overrides: Partial<FleetEvent> = {},
): FleetEvent => ({
  id: `event-${status}`,
  fleetId: fleet.id,
  title: "Jumptown Convoy Escort",
  slug: `jumptown-${status}`,
  description:
    "Two Connies riding shotgun on a laden Hull-C out of Levski. Comms discipline expected.",
  status,
  startsAt: NOW,
  timezone: "UTC",
  location: "Levski, Delamar",
  meetupLocation: "Port Olisar, Pad 7",
  visibility: FleetEventVisibility.fleet,
  category: FleetEventCategory.cargo_hauling,
  autoLockEnabled: true,
  signupApproval: FleetEventSignupApproval.direct,
  archived: false,
  externalUid: "uid-1",
  signupsCount: 14,
  teamCount: 2,
  past: false,
  signupsOpen: true,
  discordConfigured: false,
  recurring: true,
  createdAt: NOW,
  updatedAt: NOW,
  ...overrides,
});

// Every lifecycle state, which is what D1 moved onto the panel's end-cap.
const lifecycle: Array<{ status: FleetEventStatus; past?: boolean }> = [
  { status: FleetEventStatus.draft },
  { status: FleetEventStatus.open },
  { status: FleetEventStatus.locked },
  { status: FleetEventStatus.active },
  { status: FleetEventStatus.completed },
  { status: FleetEventStatus.cancelled },
  // A past event still sitting in `open` reads as past, not as open signups.
  { status: FleetEventStatus.open, past: true },
];

const signup = (
  username: string,
  status: FleetEventSignupStatus,
  overrides: Partial<FleetEventSignup> = {},
): FleetEventSignup => ({
  id: `signup-${username}`,
  fleetEventId: "event-open",
  status,
  user: { id: `user-${username}`, username },
  ...overrides,
});

const slot = (
  title: string,
  overrides: Partial<FleetEventSlot> = {},
): FleetEventSlot => ({
  id: `slot-${title}`,
  slottableType: FleetEventSlotSlottableType.FleetEventShip,
  slottableId: "ship-1",
  title,
  position: 0,
  derived: false,
  effectiveSignupApproval: FleetEventSlotEffectiveSignupApproval.direct,
  signups: [],
  ...overrides,
});

const openEvent = eventFor(FleetEventStatus.open);

// The four row states: free, taken by someone else, taken by you, and a
// tentative signup whose ship does not match the slot.
const slots: FleetEventSlot[] = [
  slot("Pilot", { positionType: "Command" }),
  slot("Co-pilot / Scanner", {
    positionType: "Support",
    signups: [signup("ThalosVex", FleetEventSignupStatus.confirmed)],
  }),
  slot("Turret — dorsal", {
    positionType: "Gunner",
    signups: [signup("Marrow_K", FleetEventSignupStatus.tentative)],
  }),
  slot("Engineering", {
    positionType: "Support",
    description:
      "Bring repair components; expect hull damage on the return leg.",
  }),
];

const ship = (overrides: Partial<FleetEventShip> = {}): FleetEventShip => ({
  id: "ship-1",
  fleetEventTeamId: "team-1",
  position: 0,
  strict: false,
  slots,
  title: "Escort — Constellation",
  description: "Shields up, stay on the Hull-C's port side.",
  filters: { classification: "Combat", minCrew: 3, minCargo: 96 },
  ...overrides,
});

const team: FleetEventTeam = {
  id: "team-1",
  fleetEventId: openEvent.id,
  title: "Escort Wing",
  position: 0,
  slots: [],
  ships: [ship()],
};

const mission: Mission = {
  id: "mission-1",
  title: "Standing Jumptown Run",
  slug: "standing-jumptown-run",
  category: MissionCategory.cargo_hauling,
  archived: false,
  teamCount: 2,
  shipCount: 5,
  description: "The reusable template the weekly escort is spawned from.",
  createdAt: NOW,
  updatedAt: NOW,
};

const archivedMission: Mission = {
  ...mission,
  id: "mission-2",
  slug: "retired-run",
  title: "Retired Run",
  archived: true,
};

const CURRENT_USER = "user-ThalosVex";
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Event card, by lifecycle</Heading>
  <p>
    The tone is on the panel's end-cap, per D1 — the frame stays neutral. The
    chip beside the title names it, so the state is never carried by colour
    alone. The last card is a past event still sitting in <code>open</code>.
  </p>
  <div class="row">
    <div
      v-for="entry in lifecycle"
      :key="`${entry.status}-${entry.past}`"
      class="col-12 col-md-6 col-lg-4"
    >
      <EventPanel
        :fleet="fleet"
        :event="eventFor(entry.status, { past: entry.past })"
        can-manage
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Mission card</Heading>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-4">
      <MissionPanel :fleet="fleet" :mission="mission" />
    </div>
    <div class="col-12 col-md-6 col-lg-4">
      <MissionPanel :fleet="fleet" :mission="archivedMission" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Signup CTA</Heading>
  <p>
    Three peers in a plain group, not a segmented one: these submit rather than
    select, and nothing is chosen while this renders.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <EventSignupCta
        :fleet-slug="fleet.slug"
        :event="openEvent"
        :signups-locked="false"
      />
    </div>
    <div class="col-12 col-lg-6">
      <EventSignupCta
        :fleet-slug="fleet.slug"
        :event="openEvent"
        signups-locked
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Slot rows</Heading>
  <p>
    List rows sharing one hairline, not nested cards. The second row is yours —
    the left rail is <code>metrics-card__tile--primary</code>'s, and the chip
    carries an icon as well as a tint.
  </p>
  <div class="row">
    <div class="col-12 col-lg-8">
      <div class="vt-surface">
        <EventSlotRow
          v-for="entry in slots"
          :key="entry.id"
          :slot-data="entry"
          :fleet="fleet"
          :event="openEvent"
          :current-user-id="CURRENT_USER"
          :signups-locked="false"
          signups-open
        />
      </div>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Ship card</Heading>
  <p>
    Cover height comes from <code>--panel-image-height</code>; the requirements
    are metrics rows, each with its own label now that the icon strip is gone.
    The second has no image, so the placeholder shows.
  </p>
  <div class="vt-row">
    <EventShipCard
      :fleet="fleet"
      :event="openEvent"
      :team="team"
      :ship="ship()"
      :current-user-id="CURRENT_USER"
      signups-open
    />
    <EventShipCard
      :fleet="fleet"
      :event="openEvent"
      :team="team"
      :ship="ship({ id: 'ship-2', title: 'Any medium freighter' })"
      :current-user-id="CURRENT_USER"
      signups-open
    />
  </div>
</template>

<style lang="scss" scoped>
.vt-row {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 20px;
  margin-bottom: 20px;
}

// Slot rows are designed to sit inside a panel body, so the rig gives them one.
.vt-surface {
  background: var(--color-surface, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
  padding: 4px 18px;
  margin-bottom: 20px;
}
</style>
