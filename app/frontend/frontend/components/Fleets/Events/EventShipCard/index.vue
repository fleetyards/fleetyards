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
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";
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
    { mediumUrl?: string; smallUrl?: string } | undefined;
  return img?.mediumUrl || img?.smallUrl;
});

const hasShipImage = computed(() => !!shipImage.value);

const effectiveMinCrew = computed<number | null>(() => {
  const override = props.ship.filters?.minCrew;
  if (override != null) return override;
  const model = props.ship.model as
    { minCrew?: number | null } | null | undefined;
  return model?.minCrew ?? null;
});

const minCrewIsOverride = computed(
  () => props.ship.filters?.minCrew != null && !!props.ship.model,
);

// Every requirement carries its own label now that these render as rows rather
// than as an icon strip: the label is what says which figure you are reading,
// so classification, focus and cargo can no longer rely on a glyph for it.
type StatItem = { label: string; value: string };

const filterStrip = computed<StatItem[]>(() => {
  if (props.ship.model) return [];
  const f = props.ship.filters;
  if (!f) return [];
  const items: StatItem[] = [];
  if (f.classification)
    items.push({
      label: t("labels.fleets.missions.classification"),
      value: f.classification,
    });
  if (f.focus)
    items.push({ label: t("labels.fleets.missions.focus"), value: f.focus });
  if (f.minSize)
    items.push({
      label: t("labels.fleets.missions.minSize"),
      value: f.minSize,
    });
  if (f.maxSize)
    items.push({
      label: t("labels.fleets.missions.maxSize"),
      value: f.maxSize,
    });
  if (f.minCrew != null)
    items.push({
      label: t("labels.fleets.missions.minCrew"),
      value: String(f.minCrew),
    });
  if (f.minCargo != null)
    items.push({
      label: t("labels.fleets.missions.minCargo"),
      value: String(f.minCargo),
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
    :bg-rounded="PanelRoundedEnum.TOP"
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
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            class="ship-context-menu"
            expand-left
            expand-bottom
            inline
          >
            <Btn
              :size="BtnSizesEnum.SM"
              :inline="true"
              @click="openEditShipModal"
            >
              <i class="fa fa-pencil" />
              <span>{{ t("actions.edit") }}</span>
            </Btn>
            <Btn
              :size="BtnSizesEnum.SM"
              :inline="true"
              tone="danger"
              @click="removeShip"
            >
              <i class="fa-light fa-trash" />
              <span>{{ t("actions.delete") }}</span>
            </Btn>
          </BtnDropdown>
        </template>
      </PanelHeading>
    </template>

    <!-- Below the cover. The heading is the only thing that belongs on it. -->
    <template #footer>
      <PanelBody>
        <div
          v-if="effectiveMinCrew != null || filterStrip.length"
          class="metrics-card__rows"
        >
          <div v-if="effectiveMinCrew != null" class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.fleets.missions.minCrew") }}
            </div>
            <div class="metrics-card__row__value">
              {{ effectiveMinCrew }}
              <span v-if="minCrewIsOverride" class="event-ship-card__override">
                {{ t("labels.fleets.missions.minCrewOverride") }}
              </span>
            </div>
          </div>
          <div
            v-for="(item, idx) in filterStrip"
            :key="idx"
            class="metrics-card__row"
          >
            <div class="metrics-card__row__label">{{ item.label }}</div>
            <div class="metrics-card__row__value">{{ item.value }}</div>
          </div>
        </div>

        <p v-if="ship.description" class="event-ship-card__desc">
          {{ ship.description }}
        </p>

        <div class="event-ship-card__slots">
          <p class="metrics-card__section-label">
            {{ t("headlines.fleets.missions.slots") }}
          </p>
          <EventSlotList
            v-if="editable"
            slottable-type="FleetEventShip"
            :slottable-id="ship.id"
            :slots="ship.slots"
            editable
          />
          <div v-else>
            <EventSlotRow
              v-for="slot in ship.slots as FleetEventSlot[]"
              :key="slot.id"
              :slot-data="slot"
              :ship="ship"
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
      </PanelBody>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

/*
 * The cover height, replacing four :deep() rules into Panel's internals - two of
 * which stopped matching anything when the redesign collapsed .panel-inner into
 * .panel__inner, so the card had already lost its content offset.
 */
.event-ship-panel {
  --panel-image-height: 160px;
  width: 380px;
  min-width: 350px;
  flex-shrink: 0;
}

.ship-placeholder {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(
    180deg,
    rgba(60, 70, 90, 0.4) 0%,
    rgba(20, 25, 35, 0.7) 100%
  );
  /* The panel's radius less its border, which is what the frame actually rounds
     to. $panelInnerBorderRadius is 20px and overhung it by 6. */
  border-top-left-radius: var(--radius-surface-inner, 14px);
  border-top-right-radius: var(--radius-surface-inner, 14px);
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
  gap: 8px;
}

.ship-drag-handle {
  cursor: grab;
  color: var(--color-muted, #7a8288);
  font-size: 13px;
  letter-spacing: -0.15em;
  user-select: none;
}

.ship-subtitle {
  font-size: 13px;
  color: var(--color-muted, #7a8288);
}

/* The qualifier beside a value, borrowing the metrics tile's unit treatment
   rather than the 999px tinted pill it replaces. */
.event-ship-card__override {
  font-family: "Open Sans", sans-serif;
  font-weight: 600;
  font-size: 12px;
  letter-spacing: 0.08em;
  color: var(--color-gray-light, #7a8288);
  margin-left: 6px;
}

.event-ship-card__desc {
  margin: 14px 0 0;
  font-size: 14px;
  color: var(--color-muted, #7a8288);
}

.event-ship-card__slots {
  margin-top: 18px;
}
</style>
