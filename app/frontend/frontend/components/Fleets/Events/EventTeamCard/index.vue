<script lang="ts">
export default {
  name: "FleetEventsTeamCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
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
  <Panel :variant="PanelVariantsEnum.SLIM" class="event-team-box">
    <!--
      The three controls here were bare <button> elements with their own hover
      rules, one of which reached for a --danger that was never declared. They
      are Btn now, at chip scale, so a card's actions match every other action
      in the app - and each has a translated accessible name in place of the
      untranslated title="Drag".
    -->
    <!--
      Slim with a divider, per D6: a team is a titled sub-surface inside a page,
      not a card in its own right. The full frame's 2px edge, 16px radius and
      end-caps made a page of teams read as a stack of competing surfaces.
    -->
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      <template #default>
        <span class="event-team-title-row">
          <span
            v-if="editable"
            v-tooltip="t('actions.reorder')"
            class="event-team-drag-handle"
            :aria-label="t('actions.reorder')"
          >
            <i class="fa-light fa-grip-vertical" />
          </span>
          {{ team.title }}
        </span>
      </template>
      <template v-if="editable" #actions>
        <Btn
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.edit')"
          v-tooltip="t('actions.edit')"
          @click="openEditTeamModal"
        >
          <i class="fa-light fa-pen" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          tone="danger"
          :aria-label="t('actions.delete')"
          v-tooltip="t('actions.delete')"
          @click="removeTeam"
        >
          <i class="fa-light fa-xmark" />
        </Btn>
      </template>
    </PanelHeading>

    <PanelBody>
      <p v-if="team.description" class="event-team-desc">
        {{ team.description }}
      </p>

      <div class="event-team-section">
        <p class="metrics-card__section-label">
          {{ t("headlines.fleets.missions.slots") }}
        </p>
        <EventSlotList
          v-if="editable"
          slottable-type="FleetEventTeam"
          :slottable-id="team.id"
          :slots="team.slots"
          editable
        />
        <div v-else>
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
          <p class="metrics-card__section-label">
            {{ t("headlines.fleets.missions.ships") }}
          </p>
          <Btn
            v-if="editable"
            :size="BtnSizesEnum.XS"
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
        <p v-if="!ships.length" class="event-team-no-ships">
          {{ t("labels.fleets.missions.noShips") }}
        </p>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

/*
 * The frame is Panel's now. What was here - a rgba(0,0,0,.45) fill at radius 6
 * inside a 1px edge, plus three hand-styled bare buttons with their own hover
 * transitions - is what D6 of the plan replaces wholesale.
 */
.event-team-title-row {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.event-team-drag-handle {
  cursor: grab;
  color: var(--color-muted, #7a8288);
  font-size: 13px;
  user-select: none;
}

.event-team-desc {
  margin: 0 0 18px;
  color: var(--color-muted, #7a8288);
}

.event-team-section + .event-team-section {
  margin-top: 22px;
}

.event-team-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;

  /* The label carries its own bottom margin for the stacked case; beside a
     button it would push the row out of alignment. */
  .metrics-card__section-label {
    margin-bottom: 0;
  }
}

.event-team-ships {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  align-items: flex-start;
  margin-top: 12px;
}

.event-team-no-ships {
  margin: 12px 0 0;
  font-size: 14px;
  color: var(--color-muted, #7a8288);
}
</style>
