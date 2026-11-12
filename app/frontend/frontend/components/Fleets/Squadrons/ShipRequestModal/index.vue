<script lang="ts">
export default {
  name: "FleetSquadronShipRequestModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import {
  type VehiclePublic,
  useFleetVehicles,
  useCreateFleetSquadronShipRequest,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadronSlug: string;
  username: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

// What the member shares with the fleet, and separately what the squadron
// already gets: only the difference can be asked for.
const { data: fleetShips, isLoading } = useFleetVehicles(
  computed(() => props.fleetSlug),
  computed(() => ({ perPage: "240", q: { memberIn: [props.username] } })),
);

const { data: squadronShips } = useFleetVehicles(
  computed(() => props.fleetSlug),
  computed(() => ({
    perPage: "240",
    q: { memberIn: [props.username], squadronSlugIn: [props.squadronSlug] },
  })),
);

const askable = computed(() => {
  const given = new Set(
    ((squadronShips.value?.items ?? []) as VehiclePublic[]).map((v) => v.id),
  );

  return ((fleetShips.value?.items ?? []) as VehiclePublic[]).filter(
    (vehicle) => !vehicle.loaner && !given.has(vehicle.id),
  );
});

const shipLabel = (vehicle: VehiclePublic) =>
  vehicle.name
    ? `${vehicle.name} (${vehicle.model?.name})`
    : vehicle.model?.name;

const mutation = useCreateFleetSquadronShipRequest();

const ask = async (vehicle: VehiclePublic) => {
  await mutation
    .mutateAsync({
      fleetSlug: props.fleetSlug,
      fleetSquadronSlug: props.squadronSlug,
      data: { username: props.username, vehicleId: vehicle.id },
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleet.squadrons.shipRequests.create.success", {
          username: props.username,
        }),
      });
      comlink.emit("fleet-squadron-ship-requests-updated");
      comlink.emit("close-modal", true);
    })
    .catch((error) => {
      displayAlert({
        text:
          firstErrorMessageFrom(error) ??
          t("messages.fleet.squadrons.shipRequests.create.failure"),
      });
    });
};
</script>

<template>
  <Modal
    :title="
      t('headlines.fleets.squadrons.shipRequest', { username: props.username })
    "
  >
    <p class="ship-request-hint">
      {{ t("texts.fleet.squadrons.shipRequestHint") }}
    </p>

    <Loader v-if="isLoading" :loading="true" inline />

    <ul v-else-if="askable.length" class="ship-request-list">
      <li
        v-for="vehicle in askable"
        :key="vehicle.id"
        class="ship-request-list__row"
      >
        <span>{{ shipLabel(vehicle) }}</span>
        <Btn
          :loading="mutation.isPending.value"
          :data-test="`ship-request-ask-${vehicle.id}`"
          @click="ask(vehicle)"
        >
          {{ t("actions.fleet.squadrons.askForShip") }}
        </Btn>
      </li>
    </ul>

    <Empty
      v-else
      :variant="EmptyVariantsEnum.DEFAULT"
      :name="t('labels.fleet.squadrons.askableShips')"
      inline
      hide-actions
    />
  </Modal>
</template>

<style lang="scss" scoped>
.ship-request-hint {
  margin-top: 0;
  color: var(--color-muted, #7a8288);
}

.ship-request-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.ship-request-list__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 6px 0;
  border-bottom: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
}
</style>
