<script lang="ts">
export default {
  name: "FleetEventsTeamCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import EventSlotList from "@/frontend/components/Fleets/Events/EventSlotList/index.vue";
import EventSlotRow from "@/frontend/components/Fleets/Events/EventSlotRow/index.vue";
import EventShipCard from "@/frontend/components/Fleets/Events/EventShipCard/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetEventShip,
  type FleetEventSlot,
  type FleetEventTeam,
  useDestroyFleetEventTeam,
  useSortFleetEventShips,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import Sortable from "sortablejs";

type Props = {
  fleet: Fleet;
  event: FleetEvent;
  team: FleetEventTeam;
  editable?: boolean;
  currentUserId?: string;
  signupsLocked?: boolean;
  signupsOpen?: boolean;
  ownActiveSlotId?: string | null;
  isManager?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  currentUserId: undefined,
  signupsLocked: false,
  signupsOpen: undefined,
  ownActiveSlotId: null,
  isManager: false,
});

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();

const ships = ref<FleetEventShip[]>([]);

const openEditTeamModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventTeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
      team: props.team,
    },
  });
};

const openAddShipModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventShipModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
      team: props.team,
    },
  });
};

watch(
  () => props.team.ships,
  (newShips) => {
    ships.value = [...newShips];
  },
  { immediate: true },
);

const destroyMutation = useDestroyFleetEventTeam();
const sortShipsMutation = useSortFleetEventShips();

const removeTeam = () => {
  displayConfirm({
    text: t("messages.fleets.eventTeam.destroy.confirm"),
    confirmText: t("actions.delete"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({
          fleetSlug: props.fleet.slug,
          fleetEventSlug: props.event.slug,
          id: props.team.id,
        });
        displaySuccess({
          text: t("messages.fleets.eventTeam.destroy.success"),
        });
        comlink.emit("fleet-event-children-changed");
      } catch {
        displayAlert({
          text: t("messages.fleets.eventTeam.destroy.failure"),
        });
      }
    },
  });
};

const shipsContainer = ref<HTMLElement | null>(null);
let shipsSortable: Sortable | null = null;

const initShipsSortable = () => {
  shipsSortable?.destroy();
  if (!shipsContainer.value || !props.editable) return;

  shipsSortable = Sortable.create(shipsContainer.value, {
    animation: 150,
    handle: ".ship-drag-handle",
    onEnd: () => {
      const items = shipsContainer.value?.querySelectorAll("[data-ship-id]");
      if (!items) return;
      const order = Array.from(items)
        .map((el) => el.getAttribute("data-ship-id"))
        .filter(Boolean) as string[];

      ships.value = order
        .map((id) => ships.value.find((s) => s.id === id))
        .filter(Boolean) as FleetEventShip[];

      void sortShipsMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          fleetEventSlug: props.event.slug,
          fleetEventTeamId: props.team.id,
          data: { sorting: order },
        })
        .catch(() =>
          displayAlert({
            text: t("messages.fleets.eventShip.update.failure"),
          }),
        );
    },
  });
};

watch([ships, () => props.editable], () => {
  void nextTick(() => initShipsSortable());
});

onMounted(() => {
  void nextTick(() => initShipsSortable());
});

onUnmounted(() => {
  shipsSortable?.destroy();
});
</script>

<template>
  <section class="event-team-box">
    <button
      v-if="editable"
      type="button"
      class="event-team-close"
      :title="t('actions.delete')"
      @click="removeTeam"
    >
      <i class="fa-light fa-xmark" />
    </button>

    <div class="event-team-header">
      <span v-if="editable" class="event-team-drag-handle" title="Drag">
        ⋮⋮
      </span>
      <h3 class="event-team-title">{{ team.title }}</h3>
      <button
        v-if="editable"
        type="button"
        class="event-team-edit"
        :title="t('actions.edit')"
        @click="openEditTeamModal"
      >
        <i class="fa-light fa-pen" />
      </button>
    </div>

    <p v-if="team.description" class="event-team-desc">
      {{ team.description }}
    </p>

    <div class="event-team-section">
      <h4 class="event-team-section-label">
        {{ t("headlines.fleets.missions.slots") }}
      </h4>
      <EventSlotList
        v-if="editable"
        slottable-type="FleetEventTeam"
        :slottable-id="team.id"
        :slots="team.slots"
        editable
      />
      <div v-else class="event-team-team-slots">
        <EventSlotRow
          v-for="slot in team.slots as FleetEventSlot[]"
          :key="slot.id"
          :slot-data="slot"
          :fleet="fleet"
          :event="event"
          :current-user-id="currentUserId"
          :signups-locked="signupsLocked"
          :signups-open="signupsOpen"
          :own-active-slot-id="ownActiveSlotId"
          :is-manager="isManager"
        />
      </div>
    </div>

    <div class="event-team-section">
      <div class="event-team-section-header">
        <h4 class="event-team-section-label">
          {{ t("headlines.fleets.missions.ships") }}
        </h4>
        <Btn
          v-if="editable"
          :inline="true"
          size="small"
          @click="openAddShipModal"
        >
          <i class="fa-light fa-plus" />
          <span>{{ t("actions.fleets.missions.addShip") }}</span>
        </Btn>
      </div>
      <div ref="shipsContainer" class="event-team-ships">
        <EventShipCard
          v-for="ship in ships"
          :key="ship.id"
          :data-ship-id="ship.id"
          :ship="ship"
          :fleet="fleet"
          :event="event"
          :team="team"
          :editable="editable"
          :current-user-id="currentUserId"
          :signups-locked="signupsLocked"
          :signups-open="signupsOpen"
          :own-active-slot-id="ownActiveSlotId"
          :is-manager="isManager"
        />
      </div>
      <p v-if="!ships.length" class="text-muted event-team-no-ships">
        {{ t("labels.fleets.missions.noShips") }}
      </p>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.event-team-box {
  position: relative;
  padding: 1.25rem;
  border: 1px solid var(--border, rgba(255, 255, 255, 0.1));
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.45);
  margin-bottom: 1.5rem;
}
.event-team-close {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  padding: 0.25rem 0.5rem;
  font-size: 1rem;
  line-height: 1;
  border-radius: 4px;
  transition:
    color 0.15s,
    background 0.15s;

  &:hover {
    color: var(--danger, #c66);
    background: rgba(255, 255, 255, 0.06);
  }
}
.event-team-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding-right: 2.5rem;
}
.event-team-drag-handle {
  cursor: grab;
  color: var(--text-muted);
  font-size: 0.85rem;
  letter-spacing: -0.15em;
  user-select: none;
}
.event-team-title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
}
.event-team-edit {
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  padding: 0.25rem 0.4rem;
  border-radius: 3px;
  font-size: 0.85rem;
  transition:
    color 0.15s,
    background 0.15s;

  &:hover {
    color: var(--text);
    background: rgba(255, 255, 255, 0.06);
  }
}
.event-team-desc {
  color: var(--text-muted);
  margin: 0.5rem 0 0;
}
.event-team-section {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 1rem;
}
.event-team-section-label {
  margin: 0;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}
.event-team-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
}
.event-team-ships {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: flex-start;
}
.event-team-team-slots {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.event-team-no-ships {
  font-style: italic;
  font-size: 0.9rem;
  margin: 0;
}
</style>
