<script lang="ts">
export default {
  name: "FleetSquadronShipRequestsList",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FleetSquadronShipRequest,
  useFleetSquadronShipRequests,
  useAcceptFleetSquadronShipRequest,
  useDestroyFleetSquadronShipRequest,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadronSlug: string;
  username?: string;
};

const props = withDefaults(defineProps<Props>(), { username: undefined });

const emit = defineEmits<{ accepted: [] }>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const { data: requests, refetch } = useFleetSquadronShipRequests(
  computed(() => props.fleetSlug),
  computed(() => props.squadronSlug),
);

const forMe = computed(() =>
  (requests.value ?? []).filter(
    (request) => request.member.username === props.username,
  ),
);

// Everyone else's: only a roster manager is sent these.
const forOthers = computed(() =>
  (requests.value ?? []).filter(
    (request) => request.member.username !== props.username,
  ),
);

const shipLabel = (request: FleetSquadronShipRequest) =>
  request.vehicle.name
    ? `${request.vehicle.name} (${request.vehicle.model?.name})`
    : request.vehicle.model?.name;

const acceptMutation = useAcceptFleetSquadronShipRequest();
const destroyMutation = useDestroyFleetSquadronShipRequest();

const accept = async (request: FleetSquadronShipRequest) => {
  await acceptMutation
    .mutateAsync({
      fleetSlug: props.fleetSlug,
      fleetSquadronSlug: props.squadronSlug,
      id: request.id,
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleet.squadrons.shipRequests.accept.success"),
      });
      emit("accepted");
      void refetch();
    })
    .catch(() => {
      displayAlert({
        text: t("messages.fleet.squadrons.shipRequests.accept.failure"),
      });
    });
};

const dismiss = async (request: FleetSquadronShipRequest) => {
  await destroyMutation
    .mutateAsync({
      fleetSlug: props.fleetSlug,
      fleetSquadronSlug: props.squadronSlug,
      id: request.id,
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleet.squadrons.shipRequests.destroy.success"),
      });
      void refetch();
    })
    .catch(() => {
      displayAlert({
        text: t("messages.fleet.squadrons.shipRequests.destroy.failure"),
      });
    });
};

const offRequestsUpdated = ref<() => void>();

onMounted(() => {
  offRequestsUpdated.value = comlink.on(
    "fleet-squadron-ship-requests-updated",
    () => void refetch(),
  );
});

onUnmounted(() => {
  offRequestsUpdated.value?.();
});
</script>

<template>
  <section v-if="forMe.length" class="ship-requests">
    <Heading :level="HeadingLevelEnum.H3">
      {{ t("headlines.fleets.squadrons.shipRequestsForMe") }}
    </Heading>
    <ul class="ship-requests__list">
      <li
        v-for="request in forMe"
        :key="request.id"
        class="ship-requests__row"
        :data-test="`ship-request-${request.id}`"
      >
        <span class="ship-requests__text">
          {{
            t("labels.fleet.squadrons.shipRequestFrom", {
              ship: shipLabel(request),
              username: request.requestedByUsername ?? "?",
            })
          }}
        </span>
        <Btn
          :size="BtnSizesEnum.SM"
          :loading="acceptMutation.isPending.value"
          data-test="ship-request-accept"
          @click="accept(request)"
        >
          {{ t("actions.fleet.squadrons.acceptRequest") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          data-test="ship-request-decline"
          @click="dismiss(request)"
        >
          {{ t("actions.fleet.squadrons.declineRequest") }}
        </Btn>
      </li>
    </ul>
  </section>

  <section v-if="forOthers.length" class="ship-requests">
    <Heading :level="HeadingLevelEnum.H3">
      {{ t("headlines.fleets.squadrons.shipRequestsOpen") }}
    </Heading>
    <ul class="ship-requests__list">
      <li
        v-for="request in forOthers"
        :key="request.id"
        class="ship-requests__row"
      >
        <span class="ship-requests__text">
          {{
            t("labels.fleet.squadrons.shipRequestTo", {
              ship: shipLabel(request),
              username: request.member.username,
            })
          }}
        </span>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          @click="dismiss(request)"
        >
          {{ t("actions.fleet.squadrons.withdrawShipRequest") }}
        </Btn>
      </li>
    </ul>
  </section>
</template>

<style lang="scss" scoped>
.ship-requests {
  margin-bottom: 24px;
}

.ship-requests__list {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
}

.ship-requests__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  padding: 8px 0;
  border-bottom: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
}

.ship-requests__text {
  flex: 1;
  min-width: 200px;
}
</style>
