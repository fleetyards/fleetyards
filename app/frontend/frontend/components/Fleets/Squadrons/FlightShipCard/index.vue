<script lang="ts">
export default {
  name: "FleetSquadronFlightShipCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type LineupScope,
  useLineupApi,
} from "@/frontend/components/Fleets/Missions/useLineupApi";
import {
  type Fleet,
  type FleetSquadronSlotCandidate,
  type MissionShip,
  type MissionSlot,
} from "@/services/fyApi";
import {
  sortByFilled,
  useSlotTitle,
} from "@/frontend/composables/useSlotTitle";

type Props = {
  fleet: Fleet;
  scope: LineupScope;
  ship: MissionShip;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const lineup = useLineupApi(() => props.scope);
const slotTitle = useSlotTitle();

const changed = () => comlink.emit("mission-children-changed");

const seats = computed(() => props.ship.slots ?? []);

// The card shows who flies; seats nobody is listed for are filled in the
// seats modal.
const filledSeats = computed(() =>
  sortByFilled(seats.value.filter((seat) => seat.candidates?.length)),
);

// Enough to read the crew at a glance; the rest are a click away.
const VISIBLE_SEATS = 5;

const visibleSeats = computed(() => filledSeats.value.slice(0, VISIBLE_SEATS));

const hiddenCount = computed(() =>
  Math.max(0, filledSeats.value.length - VISIBLE_SEATS),
);

const roleLabel = (seat: MissionSlot) =>
  seat.role ? t(`labels.fleet.squadrons.flights.roles.${seat.role}`) : null;

const openCount = computed(() => seats.value.length - filledSeats.value.length);

// A spot naming one model shows it; one listing several shows the first, and a
// spot that only sets criteria has no ship to show.
const imageUrl = computed(() => {
  const model = props.ship.model ?? props.ship.allowedModels?.[0];

  return model?.angledView?.mediumUrl || model?.image?.mediumUrl;
});

const title = computed(
  () => props.ship.displayTitle ?? props.ship.title ?? props.ship.model?.name,
);

const spec = computed(() => {
  const vehicle = props.ship.vehicle;
  if (vehicle) {
    const name = [vehicle.name, props.ship.model?.name]
      .filter((part) => part && part !== title.value)
      .join(" · ");
    const owner = vehicle.username
      ? t("labels.fleet.squadrons.flights.shipOf", {
          username: vehicle.username,
        })
      : null;

    return [name, owner].filter(Boolean).join(" · ");
  }

  if (props.ship.model) {
    return props.ship.model.name !== title.value
      ? props.ship.model.name
      : t("labels.fleet.squadrons.flights.exactModel");
  }

  if (props.ship.allowedModels?.length) {
    return `${t("labels.fleets.missions.anyOf")} ${props.ship.allowedModels
      .map((model) => model.name)
      .join(", ")}`;
  }

  const filters = props.ship.filters;

  return [filters?.classification, ...(filters?.fociLabels ?? [])]
    .filter(Boolean)
    .join(" · ");
});

const primary = (seat: MissionSlot): FleetSquadronSlotCandidate | undefined =>
  seat.candidates?.[0];

const primaryLine = (seat: MissionSlot) => {
  const candidate = primary(seat);
  if (!candidate) return "";

  const ship = candidate.vehicle?.name || candidate.vehicle?.model?.name;

  return ship ? `${candidate.username} · ${ship}` : candidate.username;
};

const alternatesLine = (seat: MissionSlot) => {
  const alternates = (seat.candidates ?? []).slice(1);

  if (alternates.length) {
    return t("labels.fleet.squadrons.flights.then", {
      names: alternates.map((candidate) => candidate.username).join(", "),
    });
  }

  return t("labels.fleet.squadrons.flights.noAlternates");
};

const openSeats = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/ShipSeatsModal/index.vue"),
    props: {
      scope: props.scope,
      shipId: props.ship.id,
      shipTitle: title.value,
      editable: props.editable,
    },
  });
};

const openCandidates = (seat: MissionSlot) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SlotCandidatesModal/index.vue"),
    props: { slot: seat, scope: props.scope },
  });
};

const openEditShip = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/ShipModal/index.vue"),
    props: { fleet: props.fleet, ship: props.ship, scope: props.scope },
  });
};

const removeShip = async () => {
  await lineup
    .destroyShip(props.ship.id)
    .then(changed)
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionShip.destroy.failure") }),
    );
};
</script>

<template>
  <section class="flight-ship" :data-test="`flight-ship-${ship.id}`">
    <div v-if="editable" class="flight-ship__actions">
      <Btn
        v-tooltip="t('actions.edit')"
        :size="BtnSizesEnum.XS"
        :variant="BtnVariantsEnum.BARE"
        :aria-label="t('actions.edit')"
        data-test="flight-ship-edit"
        @click="openEditShip"
      >
        <i class="fa-light fa-pen" />
      </Btn>
      <Btn
        v-tooltip="t('actions.delete')"
        :size="BtnSizesEnum.XS"
        :variant="BtnVariantsEnum.BARE"
        tone="danger"
        :aria-label="t('actions.delete')"
        @click="removeShip"
      >
        <i class="fa-light fa-trash" />
      </Btn>
    </div>

    <div class="flight-ship__render">
      <img
        v-if="imageUrl"
        :src="imageUrl"
        :alt="title"
        class="flight-ship__image"
        loading="lazy"
      />
      <i v-else class="fa-duotone fa-rocket-launch flight-ship__placeholder" />
    </div>

    <header class="flight-ship__header">
      <div class="flight-ship__names">
        <span class="flight-ship__title">{{ title }}</span>
        <span v-if="spec" class="flight-ship__spec">{{ spec }}</span>
      </div>
      <span class="flight-ship__filled">
        {{ filledSeats.length }} / {{ seats.length }}
      </span>
    </header>

    <ul v-if="filledSeats.length" class="flight-ship__seats">
      <li
        v-for="seat in visibleSeats"
        :key="seat.id"
        class="flight-ship__seat"
        :data-test="`flight-ship-seat-${seat.id}`"
      >
        <Avatar :avatar="primary(seat)?.avatar?.smallUrl" size="small" />
        <div class="flight-ship__seat-text">
          <span class="flight-ship__seat-title">
            {{ slotTitle(seat) }}
            <span v-if="roleLabel(seat)" class="flight-ship__role">
              {{ roleLabel(seat) }}
            </span>
          </span>
          <span class="flight-ship__seat-who">{{ primaryLine(seat) }}</span>
          <span class="flight-ship__seat-then">{{ alternatesLine(seat) }}</span>
        </div>
        <Btn
          v-if="editable"
          v-tooltip="t('actions.fleet.squadrons.flights.editCandidates')"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.fleet.squadrons.flights.editCandidates')"
          class="flight-ship__seat-edit"
          :data-test="`flight-ship-seat-members-${seat.id}`"
          @click="openCandidates(seat)"
        >
          <i class="fa-light fa-user-pen" />
        </Btn>
      </li>
    </ul>

    <button
      v-if="hiddenCount"
      type="button"
      class="flight-ship__more"
      data-test="flight-ship-more-seats"
      @click="openSeats"
    >
      {{
        t("actions.fleet.squadrons.flights.moreSeats", { count: hiddenCount })
      }}
    </button>

    <footer class="flight-ship__footer">
      <span v-if="openCount" class="flight-ship__open-count">
        {{
          t("labels.fleet.squadrons.flights.openSeats", { count: openCount })
        }}
      </span>
      <Btn
        v-if="editable"
        :size="BtnSizesEnum.SM"
        class="flight-ship__seats-btn"
        data-test="flight-ship-seats"
        @click="openSeats"
      >
        <i class="fa-light fa-user-gear" />
        {{ t("actions.fleet.squadrons.flights.manageSeats") }}
      </Btn>
    </footer>
  </section>
</template>

<style lang="scss" scoped>
.flight-ship {
  position: relative;
  overflow: hidden;
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-surface-slim);
  background: var(--color-surface);
  box-shadow: var(--shadow-surface-slim);
}

.flight-ship__render {
  display: grid;
  height: 132px;
  padding: 12px 20px 0;
  background: radial-gradient(
    ellipse at 50% 70%,
    rgb(66 139 202 / 0.12),
    transparent 70%
  );
  place-items: center;
}

.flight-ship__image {
  max-width: 100%;
  max-height: 120px;
  object-fit: contain;
  filter: drop-shadow(0 10px 14px rgb(0 0 0 / 0.7));
}

.flight-ship__placeholder {
  color: var(--color-muted);
  font-size: 2.5rem;
}

.flight-ship__header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 14px;
  border-bottom: 1px solid var(--color-edge-soft);
}

.flight-ship__names {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;
}

.flight-ship__title {
  font-weight: 600;
}

.flight-ship__spec,
.flight-ship__filled {
  color: var(--color-text-dim);
  font-size: 0.75rem;
}

.flight-ship__filled {
  white-space: nowrap;
}

/* Over the render's corner, out of the way until the card is pointed at or
   one of its buttons has focus; a touch screen has no hover, so it keeps them. */
.flight-ship__actions {
  position: absolute;
  top: 8px;
  right: 8px;
  z-index: 1;
  display: flex;
  border-radius: var(--radius-control);
  background: var(--color-control);
  opacity: 0;
  transition: opacity 150ms ease;
}

.flight-ship:hover .flight-ship__actions,
.flight-ship__actions:focus-within {
  opacity: 1;
}

@media (hover: none) {
  .flight-ship__actions {
    opacity: 1;
  }
}

.flight-ship__seat-edit {
  opacity: 0;
  transition: opacity 150ms ease;
}

.flight-ship__seat:hover .flight-ship__seat-edit,
.flight-ship__seat-edit:focus-visible {
  opacity: 1;
}

@media (hover: none) {
  .flight-ship__seat-edit {
    opacity: 1;
  }
}

.flight-ship__role {
  margin-left: 6px;
  padding: 0 5px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 4px;
}

.flight-ship__more {
  display: block;
  width: 100%;
  padding: 8px 14px;
  border: 0;
  border-bottom: 1px solid var(--color-edge-faint);
  background: transparent;
  color: var(--color-primary);
  font: inherit;
  font-size: 0.8125rem;
  font-weight: 600;
  text-align: left;
  cursor: pointer;

  &:hover {
    background: var(--color-control-hover);
  }
}

.flight-ship__seats {
  margin: 0;
  padding: 4px 0;
  list-style: none;
}

.flight-ship__seat {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 14px;
  border-bottom: 1px solid var(--color-edge-faint);
}

.flight-ship__seat-text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.flight-ship__seat-title {
  color: var(--color-text-dim);
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.flight-ship__seat-who {
  font-weight: 600;
}

.flight-ship__seat-then {
  color: var(--color-muted);
  font-size: 0.75rem;
}

.flight-ship__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 10px 14px 12px;
}

.flight-ship__open-count {
  color: var(--color-muted);
  font-size: 0.75rem;
}

.flight-ship__seats-btn {
  margin-left: auto;
}
</style>
