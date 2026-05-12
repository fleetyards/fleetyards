<script lang="ts">
export default {
  name: "FleetEventManagePage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import NotAuthorized from "@/shared/components/NotAuthorized/index.vue";
import EventStatusBadge from "@/frontend/components/Fleets/Events/EventStatusBadge/index.vue";
import EventActions from "@/frontend/components/Fleets/Events/EventActions/index.vue";
import EventTeamCard from "@/frontend/components/Fleets/Events/EventTeamCard/index.vue";
import UnassignedSignups from "@/frontend/components/Fleets/Events/UnassignedSignups/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetEventTeam,
  type FleetEventShip,
  type FleetEventSlot,
  type FleetEventSignup,
  useFleetEvent,
  useDestroyFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { format, parseISO } from "date-fns";
import { useSessionStore } from "@/frontend/stores/session";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();
const route = useRoute();
const session = useSessionStore();

const fleetSlug = computed(() => props.fleet.slug);
const eventSlug = computed(() => route.params.event as string);

const { data: event, refetch } = useFleetEvent(fleetSlug, eventSlug);

const destroyMutation = useDestroyFleetEvent();

const canManage = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:update",
  ]),
);

const canDelete = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:delete",
  ]),
);

const viewerEventRole = computed(
  () =>
    (event.value as { viewerEventRole?: string | null } | undefined)
      ?.viewerEventRole ?? null,
);

const isEventCreator = computed(
  () => viewerEventRole.value === "creator" || canManage.value,
);

const isEventManager = computed(() => {
  if (canManage.value) return true;
  return ["creator", "admin", "moderator"].includes(
    viewerEventRole.value ?? "",
  );
});

const currentUserId = computed(() => session.currentUser?.id);

const unassignedSignups = computed(
  () =>
    (event.value as { unassignedSignups?: FleetEventSignup[] } | undefined)
      ?.unassignedSignups ?? [],
);

const signupsLocked = computed(
  () =>
    !event.value ||
    ["draft", "locked", "active", "completed", "cancelled"].includes(
      event.value.status,
    ),
);

const signupsOpenForEvent = computed(() => !!event.value?.signupsOpen);

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

const ownActiveSlotId = computed<string | null>(() => {
  const userId = currentUserId.value;
  if (!userId) return null;
  for (const ctx of allSlotsWithContext.value) {
    const signup = (ctx.slot.signups ?? []).find((s) => s.user?.id === userId);
    if (signup) return ctx.slot.id;
  }
  return null;
});

const startDate = computed(() => {
  if (!event.value) return "";
  try {
    return format(parseISO(event.value.startsAt), "EEE, MMM d, yyyy · HH:mm");
  } catch {
    return event.value.startsAt;
  }
});

const goToEdit = () => {
  if (!event.value) return;
  void router.push({
    name: "fleet-event-edit",
    params: { slug: props.fleet.slug, event: event.value.slug },
  });
};

const goToDetail = () => {
  if (!event.value) return;
  void router.push({
    name: "fleet-event",
    params: { slug: props.fleet.slug, event: event.value.slug },
  });
};

const openAddTeamModal = () => {
  if (!event.value) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventTeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: event.value,
    },
  });
};

const openAdminsModal = () => {
  if (!event.value) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventAdminsModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: event.value,
    },
  });
};

const performDestroy = async () => {
  if (!event.value) return;
  const wasArchived = event.value.archived;
  try {
    await destroyMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: event.value.slug,
    });
    displaySuccess({
      text: wasArchived
        ? t("messages.fleets.event.destroy.success")
        : t("messages.fleets.event.archive.success"),
    });
    if (wasArchived) {
      void router.push({
        name: "fleet-events",
        params: { slug: props.fleet.slug },
      });
    } else {
      void refetch();
    }
  } catch {
    displayAlert({
      text: wasArchived
        ? t("messages.fleets.event.destroy.failure")
        : t("messages.fleets.event.archive.failure"),
    });
  }
};

const handleDestroy = () => {
  if (!event.value) return;
  const archived = event.value.archived;
  displayConfirm({
    text: archived
      ? t("messages.fleets.event.destroy.confirm")
      : t("messages.fleets.event.archive.confirm"),
    confirmText: archived
      ? t("actions.fleets.events.destroy")
      : t("actions.fleets.events.archive"),
    onConfirm: performDestroy,
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
  {
    to: {
      name: "fleet-event",
      params: { slug: props.fleet.slug, event: eventSlug.value },
    },
    label: event.value?.title ?? eventSlug.value,
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <NotAuthorized v-if="event && !isEventManager" />

  <div v-else-if="event" class="event-manage">
    <header class="event-manage__header">
      <div class="event-manage__title">
        <Heading size="lg">
          {{ event.title }}
          <EventStatusBadge :status="event.status" :past="event.past" />
        </Heading>
        <p class="event-manage__meta">
          <i class="fa-light fa-calendar" />
          {{ startDate }}
          <span v-if="event.timezone" class="event-manage__tz">
            ({{ event.timezone }})
          </span>
        </p>
      </div>
      <Btn size="small" variant="link" inline @click="goToDetail">
        <i class="fa-light fa-arrow-left" />
        {{ t("actions.fleets.events.viewPublic") }}
      </Btn>
    </header>

    <Panel slim>
      <PanelBody>
        <Heading size="lg">
          {{ t("headlines.fleets.events.lifecycle") }}
        </Heading>
        <EventActions :fleet="fleet" :event="event" :can-manage="canManage" />
      </PanelBody>
    </Panel>

    <Panel slim>
      <PanelBody>
        <Heading size="lg">
          {{ t("headlines.fleets.events.settings") }}
        </Heading>
        <div class="event-manage__settings">
          <Btn v-if="canManage" size="small" inline @click="goToEdit">
            <i class="fa-light fa-pen" />
            {{ t("actions.fleets.events.edit") }}
          </Btn>
          <Btn
            v-if="isEventCreator"
            size="small"
            inline
            @click="openAdminsModal"
          >
            <i class="fa-light fa-user-shield" />
            {{ t("actions.fleets.events.manageEventTeam") }}
          </Btn>
          <Btn
            v-if="canDelete"
            size="small"
            inline
            variant="danger"
            @click="handleDestroy"
          >
            <i class="fa-light fa-trash" />
            {{
              event.archived
                ? t("actions.fleets.events.destroy")
                : t("actions.fleets.events.archive")
            }}
          </Btn>
        </div>
      </PanelBody>
    </Panel>

    <UnassignedSignups
      v-if="unassignedSignups.length"
      :signups="unassignedSignups"
      :available-slots="allSlotsWithContext"
    />

    <section class="event-manage__schedule">
      <div class="event-manage__schedule-header">
        <Heading size="lg">
          {{ t("headlines.fleets.events.schedule") }}
        </Heading>
        <Btn size="small" inline @click="openAddTeamModal">
          <i class="fa-light fa-plus" />
          {{ t("actions.fleets.events.addTeam") }}
        </Btn>
      </div>

      <p v-if="signupsLocked" class="text-muted small">
        <i class="fa-light fa-lock" />
        {{ t("labels.fleets.events.signupsLockedHint") }}
      </p>

      <EventTeamCard
        v-for="team in event.teams as FleetEventTeam[]"
        :key="team.id"
        :team="team"
        :event="event"
        :fleet="fleet"
        editable
        :current-user-id="currentUserId"
        :signups-locked="signupsLocked"
        :signups-open="signupsOpenForEvent"
        :own-active-slot-id="ownActiveSlotId"
        :is-manager="isEventManager"
        :available-slots="allSlotsWithContext"
      />

      <p v-if="!event.teams?.length" class="text-muted">
        {{ t("labels.fleets.missions.noTeams") }}
      </p>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.event-manage {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.event-manage__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  flex-wrap: wrap;
}
.event-manage__meta {
  margin: 0.25rem 0 0;
  color: rgba(255, 255, 255, 0.7);

  i {
    margin-right: 0.35rem;
  }
}
.event-manage__tz {
  font-size: 0.85em;
  opacity: 0.75;
}
.event-manage__settings {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  margin-top: 0.5rem;
}
.event-manage__schedule {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.event-manage__schedule-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}
.small {
  font-size: 0.8rem;
}
</style>
