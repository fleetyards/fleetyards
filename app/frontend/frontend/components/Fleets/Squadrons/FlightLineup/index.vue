<script lang="ts">
export default {
  name: "FleetSquadronFlightLineup",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import FlightWideSeats from "@/frontend/components/Fleets/Squadrons/FlightWideSeats/index.vue";
import FlightShipCard from "@/frontend/components/Fleets/Squadrons/FlightShipCard/index.vue";
import { type LineupScope } from "@/frontend/components/Fleets/Missions/useLineupApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetSquadron,
  type FleetSquadronFlight,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
  flight: FleetSquadronFlight;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t } = useI18n();
const comlink = useComlink();

const scope = computed<LineupScope>(() => ({
  fleetSlug: props.fleet.slug,
  squadronSlug: props.squadron.slug,
  flightId: props.flight.id,
  teamId: props.flight.teamId,
}));

const shipSeats = computed(() =>
  props.flight.ships.flatMap((ship) => ship.slots ?? []),
);

const shipSummary = computed(() =>
  t("labels.fleet.squadrons.flights.shipsSummary", {
    ships: props.flight.ships.length,
    filled: shipSeats.value.filter((seat) => seat.candidates?.length).length,
    seats: shipSeats.value.length,
  }),
);

const openAddShipModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/ShipModal/index.vue"),
    props: { fleet: props.fleet, scope: scope.value },
  });
};
</script>

<template>
  <div class="flight-lineup" :data-test="`flight-lineup-${flight.id}`">
    <FlightWideSeats
      :scope="scope"
      :seats="flight.slots"
      :editable="editable"
    />

    <section class="flight-lineup__ships-section">
      <header class="flight-lineup__header">
        <div>
          <Heading :level="HeadingLevelEnum.H2">
            {{ t("headlines.fleets.missions.ships") }}
          </Heading>
          <p class="flight-lineup__hint">{{ shipSummary }}</p>
        </div>
        <Btn
          v-if="editable"
          data-test="flight-add-ship"
          @click="openAddShipModal"
        >
          <i class="fa-light fa-plus" />
          <span>{{ t("actions.fleets.missions.addShip") }}</span>
        </Btn>
      </header>

      <div v-if="flight.ships.length" class="flight-lineup__ships">
        <FlightShipCard
          v-for="ship in flight.ships"
          :key="ship.id"
          :fleet="fleet"
          :scope="scope"
          :ship="ship"
          :editable="editable"
        />
      </div>
      <p v-else class="flight-lineup__empty">
        {{ t("labels.fleets.missions.noShips") }}
      </p>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.flight-lineup {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.flight-lineup__ships-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.flight-lineup__header {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 12px;
}

.flight-lineup__hint {
  margin: 4px 0 0;
  color: var(--color-text-dim);
  font-size: 0.8125rem;
}

.flight-lineup__ships {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  align-items: start;
}

.flight-lineup__empty {
  margin: 0;
  color: var(--color-muted);
  font-size: 0.875rem;
  font-style: italic;
}
</style>
