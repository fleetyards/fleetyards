<script lang="ts">
export default {
  name: "FleetSquadronFlightCard",
};
</script>

<script lang="ts" setup>
import Markdown from "@/shared/components/Markdown/index.vue";
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
import SlotList from "@/frontend/components/Fleets/Missions/SlotList/index.vue";
import ShipCard from "@/frontend/components/Fleets/Missions/ShipCard/index.vue";
import { type LineupScope } from "@/frontend/components/Fleets/Missions/useLineupApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type Fleet,
  type FleetSquadron,
  type FleetSquadronFlight,
  useDestroyFleetSquadronFlight,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
  flight: FleetSquadronFlight;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();

const scope = computed<LineupScope>(() => ({
  fleetSlug: props.fleet.slug,
  squadronSlug: props.squadron.slug,
  flightId: props.flight.id,
  teamId: props.flight.teamId,
}));

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/FlightModal/index.vue"),
    props: {
      fleetSlug: props.fleet.slug,
      squadronSlug: props.squadron.slug,
      flight: props.flight,
    },
  });
};

const openAddShipModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/ShipModal/index.vue"),
    props: { fleet: props.fleet, scope: scope.value },
  });
};

const destroyMutation = useDestroyFleetSquadronFlight();

const removeFlight = () => {
  displayConfirm({
    text: t("messages.fleet.squadrons.flights.destroy.confirm", {
      name: props.flight.name,
    }),
    confirmText: t("actions.delete"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          fleetSquadronSlug: props.squadron.slug,
          id: props.flight.id,
        })
        .then(() => {
          displaySuccess({
            text: t("messages.fleet.squadrons.flights.destroy.success"),
          });
          comlink.emit("mission-children-changed");
        })
        .catch(() => {
          displayAlert({
            text: t("messages.fleet.squadrons.flights.destroy.failure"),
          });
        });
    },
  });
};
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    class="flight-card"
    :data-test="`flight-${flight.id}`"
  >
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      <template #default>
        {{ flight.name }}
      </template>
      <template v-if="editable" #actions>
        <Btn
          v-tooltip="t('actions.edit')"
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.edit')"
          data-test="flight-edit"
          @click="openEditModal"
        >
          <i class="fa-light fa-pen" />
        </Btn>
        <Btn
          v-tooltip="t('actions.delete')"
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          tone="danger"
          :aria-label="t('actions.delete')"
          data-test="flight-destroy"
          @click="removeFlight"
        >
          <i class="fa-light fa-xmark" />
        </Btn>
      </template>
    </PanelHeading>

    <PanelBody>
      <Markdown
        v-if="flight.description"
        class="flight-card__desc"
        :source="flight.description"
      />

      <div class="flight-card__section">
        <p class="metrics-card__section-label">
          {{ t("headlines.fleets.missions.slots") }}
        </p>
        <SlotList
          slottable-type="MissionTeam"
          :slottable-id="flight.teamId"
          :slots="flight.slots"
          :scope="scope"
          :editable="editable"
        />
      </div>

      <div class="flight-card__section">
        <div class="flight-card__section-header">
          <p class="metrics-card__section-label">
            {{ t("headlines.fleets.missions.ships") }}
          </p>
          <Btn
            v-if="editable"
            data-test="flight-add-ship"
            @click="openAddShipModal"
          >
            <i class="fa-light fa-plus" />
            <span>{{ t("actions.fleets.missions.addShip") }}</span>
          </Btn>
        </div>
        <div class="flight-card__ships">
          <ShipCard
            v-for="ship in flight.ships"
            :key="ship.id"
            :ship="ship"
            :fleet="fleet"
            :scope="scope"
            :editable="editable"
          />
        </div>
        <p v-if="!flight.ships.length" class="text-muted flight-card__empty">
          {{ t("labels.fleets.missions.noShips") }}
        </p>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.flight-card__desc {
  margin: 8px 0 0;
  color: var(--color-muted, #7a8288);
}

.flight-card__section {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
}

.flight-card__section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.flight-card__ships {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 12px;
}

.flight-card__empty {
  margin: 0;
  font-size: 0.875rem;
  font-style: italic;
}
</style>
