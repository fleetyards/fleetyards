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
import { useSlotTitle } from "@/frontend/composables/useSlotTitle";

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

const filledCount = computed(
  () => seats.value.filter((seat) => seat.candidates?.length).length,
);

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
  if (!candidate) return t("labels.fleet.squadrons.flights.openSeat");

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

  return primary(seat)
    ? t("labels.fleet.squadrons.flights.noAlternates")
    : t("labels.fleet.squadrons.flights.nobodyListed");
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

const duplicateShip = async () => {
  await lineup
    .duplicateShip(props.ship.id)
    .then(changed)
    .catch(() =>
      displayAlert({
        text: t("messages.fleets.missionShip.duplicate.failure"),
      }),
    );
};

const removeShip = async () => {
  await lineup
    .destroyShip(props.ship.id)
    .then(changed)
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionShip.destroy.failure") }),
    );
};

const newSeat = ref("");

const addSeat = async () => {
  const seatTitle = newSeat.value.trim();
  if (!seatTitle) return;

  await lineup
    .createSlot({
      slottableType: "MissionShip",
      slottableId: props.ship.id,
      title: seatTitle,
    })
    .then(() => {
      newSeat.value = "";
      changed();
    })
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionSlot.create.failure") }),
    );
};

const removeSeat = async (seat: MissionSlot) => {
  await lineup
    .destroySlot(seat.id)
    .then(changed)
    .catch(() =>
      displayAlert({ text: t("messages.fleets.missionSlot.destroy.failure") }),
    );
};
</script>

<template>
  <section class="flight-ship" :data-test="`flight-ship-${ship.id}`">
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
        {{ filledCount }} / {{ seats.length }}
      </span>
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
          v-tooltip="t('actions.duplicate')"
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.duplicate')"
          :loading="lineup.isPending.value"
          @click="duplicateShip"
        >
          <i class="fa-light fa-copy" />
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
    </header>

    <ul class="flight-ship__seats">
      <li
        v-for="seat in seats"
        :key="seat.id"
        class="flight-ship__seat"
        :data-test="`flight-ship-seat-${seat.id}`"
      >
        <Avatar
          v-if="primary(seat)"
          :avatar="primary(seat)?.avatar?.smallUrl"
          size="small"
        />
        <span v-else class="flight-ship__open" aria-hidden="true">
          <i class="fa-light fa-plus" />
        </span>
        <div class="flight-ship__seat-text">
          <span class="flight-ship__seat-title">{{ slotTitle(seat) }}</span>
          <span
            class="flight-ship__seat-who"
            :class="{ 'flight-ship__seat-who--open': !primary(seat) }"
          >
            {{ primaryLine(seat) }}
          </span>
          <span class="flight-ship__seat-then">{{ alternatesLine(seat) }}</span>
        </div>
        <template v-if="editable">
          <Btn
            v-tooltip="t('actions.fleet.squadrons.flights.editCandidates')"
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.fleet.squadrons.flights.editCandidates')"
            :data-test="`flight-ship-seat-members-${seat.id}`"
            @click="openCandidates(seat)"
          >
            <i class="fa-light fa-user-gear" />
          </Btn>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.fleet.squadrons.flights.removeSeat')"
            @click="removeSeat(seat)"
          >
            <i class="fa-light fa-xmark" />
          </Btn>
        </template>
      </li>
    </ul>

    <form v-if="editable" class="flight-ship__new" @submit.prevent="addSeat">
      <input
        v-model="newSeat"
        type="text"
        class="flight-ship__new-input"
        :aria-label="t('actions.fleets.missions.addSlot')"
        :placeholder="t('actions.fleets.missions.addSlot')"
      />
    </form>
  </section>
</template>

<style lang="scss" scoped>
.flight-ship {
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

.flight-ship__actions {
  display: flex;
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

.flight-ship__open {
  display: grid;
  flex-shrink: 0;
  width: 30px;
  height: 30px;
  border: 1px dashed var(--color-edge-strong);
  border-radius: 50%;
  color: var(--color-muted);
  font-size: 0.75rem;
  place-items: center;
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

.flight-ship__seat-who--open {
  color: var(--color-muted);
}

.flight-ship__seat-then {
  color: var(--color-muted);
  font-size: 0.75rem;
}

.flight-ship__new {
  padding: 8px 14px 12px;
}

.flight-ship__new-input {
  width: 100%;
  padding: 6px 8px;
  border: 1px dashed var(--color-edge-soft);
  border-radius: var(--radius-control-bare);
  background: transparent;
  color: inherit;
  font: inherit;
  font-size: 0.8125rem;

  &:focus {
    border-style: solid;
    border-color: var(--color-primary);
    outline: none;
  }
}
</style>
