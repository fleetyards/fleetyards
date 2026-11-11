<script lang="ts">
export default {
  name: "FleetSquadronFlightLineup",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import SlotList from "@/frontend/components/Fleets/Missions/SlotList/index.vue";
import ShipCard from "@/frontend/components/Fleets/Missions/ShipCard/index.vue";
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
    <section class="flight-lineup__section">
      <Heading :level="HeadingLevelEnum.H2">
        {{ t("headlines.fleets.missions.slots") }}
      </Heading>
      <SlotList
        slottable-type="MissionTeam"
        :slottable-id="flight.teamId"
        :slots="flight.slots"
        :scope="scope"
        :editable="editable"
      />
    </section>

    <section class="flight-lineup__section">
      <div class="flight-lineup__section-header">
        <Heading :level="HeadingLevelEnum.H2">
          {{ t("headlines.fleets.missions.ships") }}
        </Heading>
        <Btn
          v-if="editable"
          data-test="flight-add-ship"
          @click="openAddShipModal"
        >
          <i class="fa-light fa-plus" />
          <span>{{ t("actions.fleets.missions.addShip") }}</span>
        </Btn>
      </div>
      <div class="flight-lineup__ships">
        <ShipCard
          v-for="ship in flight.ships"
          :key="ship.id"
          :ship="ship"
          :fleet="fleet"
          :scope="scope"
          :editable="editable"
        />
      </div>
      <p v-if="!flight.ships.length" class="text-muted flight-lineup__empty">
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

.flight-lineup__section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.flight-lineup__section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.flight-lineup__ships {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 12px;
}

.flight-lineup__empty {
  margin: 0;
  font-size: 0.875rem;
  font-style: italic;
}
</style>
