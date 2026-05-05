<script lang="ts">
export default {
  name: "FleetEventsShipCard",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  PanelShadowsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import EventSlotList from "@/frontend/components/Fleets/Events/EventSlotList/index.vue";
import EventSlotRow from "@/frontend/components/Fleets/Events/EventSlotRow/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetEventShip,
  type FleetEventTeam,
  type FleetEventSlot,
  useDestroyFleetEventShip,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type SlotContext = {
  slot: FleetEventSlot;
  teamTitle: string;
  shipTitle?: string;
  ship?: FleetEventShip | null;
};

type Props = {
  fleet: Fleet;
  event: FleetEvent;
  team: FleetEventTeam;
  ship: FleetEventShip;
  editable?: boolean;
  currentUserId?: string;
  signupsLocked?: boolean;
  signupsOpen?: boolean;
  ownActiveSlotId?: string | null;
  isManager?: boolean;
  availableSlots?: SlotContext[];
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  currentUserId: undefined,
  signupsLocked: false,
  signupsOpen: undefined,
  ownActiveSlotId: null,
  isManager: false,
  availableSlots: () => [],
});

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();

const openEditShipModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventShipModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
      team: props.team,
      ship: props.ship,
    },
  });
};

const destroyMutation = useDestroyFleetEventShip();

const removeShip = () => {
  displayConfirm({
    text: t("messages.fleets.eventShip.destroy.confirm"),
    confirmText: t("actions.delete"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync({
          fleetSlug: props.fleet.slug,
          fleetEventSlug: props.event.slug,
          fleetEventTeamId: props.team.id,
          id: props.ship.id,
        });
        displaySuccess({
          text: t("messages.fleets.eventShip.destroy.success"),
        });
        comlink.emit("fleet-event-children-changed");
      } catch {
        displayAlert({ text: t("messages.fleets.eventShip.destroy.failure") });
      }
    },
  });
};

const shipImage = computed<string | undefined>(() => {
  const img = props.ship.model?.image as
    | { mediumUrl?: string; smallUrl?: string }
    | undefined;
  return img?.mediumUrl || img?.smallUrl;
});

const hasShipImage = computed(() => !!shipImage.value);

const effectiveMinCrew = computed<number | null>(() => {
  const override = props.ship.filters?.minCrew;
  if (override != null) return override;
  const model = props.ship.model as
    | { minCrew?: number | null }
    | null
    | undefined;
  return model?.minCrew ?? null;
});

const minCrewIsOverride = computed(
  () => props.ship.filters?.minCrew != null && !!props.ship.model,
);

type StatItem = { icon: string; label?: string; value: string };

const filterStrip = computed<StatItem[]>(() => {
  if (props.ship.model) return [];
  const f = props.ship.filters;
  if (!f) return [];
  const items: StatItem[] = [];
  if (f.classification)
    items.push({ icon: "fa-light fa-tag", value: f.classification });
  if (f.focus) items.push({ icon: "fa-light fa-bullseye", value: f.focus });
  if (f.minSize)
    items.push({
      icon: "fa-light fa-down-left-and-up-right-to-center",
      label: t("labels.fleets.missions.minSize"),
      value: f.minSize,
    });
  if (f.maxSize)
    items.push({
      icon: "fa-light fa-up-right-and-down-left-from-center",
      label: t("labels.fleets.missions.maxSize"),
      value: f.maxSize,
    });
  if (f.minCrew != null)
    items.push({
      icon: "fa-light fa-user-group",
      label: t("labels.fleets.missions.minCrew"),
      value: String(f.minCrew),
    });
  if (f.minCargo != null)
    items.push({
      icon: "fa-light fa-box",
      value: `${f.minCargo} SCU`,
    });
  return items;
});

const headerTitle = computed(
  () => props.ship.displayTitle ?? props.ship.title ?? "—",
);

const subtitle = computed(() => {
  if (props.ship.model?.name && headerTitle.value !== props.ship.model.name) {
    return props.ship.model.name;
  }
  return null;
});
</script>

<template>
  <Panel
    class="event-ship-panel"
    :class="{ 'event-ship-panel--placeholder': !hasShipImage }"
    :bg-image="hasShipImage ? shipImage : undefined"
    :bg-rounded="PanelBgRoundedEnum.TOP"
    :shadow="PanelShadowsEnum.TOP"
  >
    <template #default>
      <div v-if="!hasShipImage" class="ship-placeholder" aria-hidden="true">
        <i class="fa-duotone fa-starship ship-placeholder-ship" />
        <i class="fa-solid fa-question ship-placeholder-question" />
      </div>
      <PanelHeading :level="HeadingLevelEnum.H4">
        <template #default>
          <span class="ship-title-row">
            <span v-if="editable" class="ship-drag-handle" title="Drag">
              ⋮⋮
            </span>
            {{ headerTitle }}
          </span>
        </template>
        <template v-if="subtitle" #subtitle>
          <span class="ship-subtitle">{{ subtitle }}</span>
        </template>
        <template v-if="editable" #actions>
          <BtnDropdown
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.LINK"
            class="ship-context-menu"
            expand-left
            expand-bottom
            inline
          >
            <Btn
              :size="BtnSizesEnum.SMALL"
              :inline="true"
              @click="openEditShipModal"
            >
              <i class="fa fa-pencil" />
              <span>{{ t("actions.edit") }}</span>
            </Btn>
            <Btn
              :size="BtnSizesEnum.SMALL"
              :inline="true"
              variant="danger"
              @click="removeShip"
            >
              <i class="fa-light fa-trash" />
              <span>{{ t("actions.delete") }}</span>
            </Btn>
          </BtnDropdown>
        </template>
      </PanelHeading>
      <div
        v-if="effectiveMinCrew != null || filterStrip.length"
        class="event-ship-stats"
      >
        <span v-if="effectiveMinCrew != null" class="event-ship-stat">
          <i class="fa-light fa-user-group" />
          <span class="event-ship-stat__label">
            {{ t("labels.fleets.missions.minCrew") }}
          </span>
          <span class="event-ship-stat__value">
            {{ effectiveMinCrew }}
          </span>
          <span v-if="minCrewIsOverride" class="event-ship-stat__badge">
            {{ t("labels.fleets.missions.minCrewOverride") }}
          </span>
        </span>
        <span
          v-for="(item, idx) in filterStrip"
          :key="idx"
          class="event-ship-stat"
        >
          <i :class="item.icon" />
          <span v-if="item.label" class="event-ship-stat__label">
            {{ item.label }}
          </span>
          <span class="event-ship-stat__value">{{ item.value }}</span>
        </span>
      </div>

      <PanelBody v-if="ship.description" class="event-ship-body">
        <p class="ship-desc">{{ ship.description }}</p>
      </PanelBody>
    </template>

    <template #footer>
      <div class="event-ship-slots">
        <h5 class="event-ship-slots-label">
          {{ t("headlines.fleets.missions.slots") }}
        </h5>
        <EventSlotList
          v-if="editable"
          slottable-type="FleetEventShip"
          :slottable-id="ship.id"
          :slots="ship.slots"
          editable
        />
        <div v-else class="event-ship-slots-list">
          <EventSlotRow
            v-for="slot in ship.slots as FleetEventSlot[]"
            :key="slot.id"
            :slot-data="slot"
            :ship="ship"
            :current-user-id="currentUserId"
            :signups-locked="signupsLocked"
            :signups-open="signupsOpen"
            :own-active-slot-id="ownActiveSlotId"
            :is-manager="isManager"
            :available-slots="availableSlots"
          />
        </div>
      </div>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
.event-ship-panel {
  width: 380px;
  min-width: 350px;
  flex-shrink: 0;
}
$shipImageHeight: 160px;

.event-ship-panel :deep(.panel-bg) {
  height: $shipImageHeight;
  bottom: auto;
}
.event-ship-panel :deep(.panel-inner) {
  padding-top: $shipImageHeight;
  position: relative;
  min-height: $shipImageHeight;
}
.event-ship-panel :deep(.panel-heading) {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: auto;
  z-index: 1;
}
.event-ship-panel :deep(.panel-body) {
  padding: 0;
}
.ship-placeholder {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(
    180deg,
    rgba(60, 70, 90, 0.4) 0%,
    rgba(20, 25, 35, 0.7) 100%
  );
  border-top-left-radius: $panelInnerBorderRadius;
  border-top-right-radius: $panelInnerBorderRadius;
  pointer-events: none;
  z-index: 0;
}
.ship-placeholder-ship {
  font-size: 4.5rem;
  color: rgba(255, 255, 255, 0.18);
}
.ship-placeholder-question {
  position: absolute;
  font-size: 1.6rem;
  color: rgba(255, 255, 255, 0.55);
  background: rgba(0, 0, 0, 0.55);
  border-radius: 50%;
  width: 2.4rem;
  height: 2.4rem;
  display: flex;
  align-items: center;
  justify-content: center;
}
.ship-title-row {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}
.ship-drag-handle {
  cursor: grab;
  color: var(--text-muted);
  font-size: 0.8rem;
  letter-spacing: -0.15em;
  user-select: none;
}
.ship-subtitle {
  font-size: 0.8rem;
  color: var(--text-muted);
}
.ship-desc {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin: 0;
}
.event-ship-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem 0.85rem;
  padding: 0.45rem 0.85rem;
  background: rgba(0, 0, 0, 0.5);
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}
.event-ship-stat {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.8rem;
  color: var(--text);

  i {
    color: var(--text-muted);
  }
}
.event-ship-stat__label {
  color: var(--text-muted);
  font-weight: 500;
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.event-ship-stat__value {
  font-weight: 600;
}
.event-ship-stat__badge {
  font-size: 0.6rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 0.05rem 0.35rem;
  border-radius: 999px;
  background: rgba(74, 170, 170, 0.2);
  color: var(--accent, #4aa);
}
.event-ship-slots {
  padding: 0.75rem 0.85rem;
  background: rgba(0, 0, 0, 0.55);
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  border-bottom-left-radius: $panelInnerBorderRadius;
  border-bottom-right-radius: $panelInnerBorderRadius;
}
.event-ship-slots-label {
  margin: 0 0 0.4rem;
  font-size: 0.65rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}
.event-ship-slots-list {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
</style>
