<script lang="ts">
export default {
  name: "FleetSquadronFlightPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import FlightLineup from "@/frontend/components/Fleets/Squadrons/FlightLineup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type Fleet,
  type FleetMember,
  useFleetSquadron,
  useFleetSquadronFlight,
  useDestroyFleetSquadronFlight,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => route.params.squadron as string);
const flightId = computed(() => route.params.flight as string);

const { data: squadron } = useFleetSquadron(fleetSlug, squadronSlug);

const {
  data: flight,
  isLoading,
  refetch,
} = useFleetSquadronFlight(fleetSlug, squadronSlug, flightId);

// Whoever arranges the roster arranges who flies together.
const canManage = computed(
  () =>
    squadron.value?.capabilities?.manageMembers ??
    props.membership?.capabilities?.manageSquadronMembers ??
    false,
);

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/FlightModal/index.vue"),
    props: {
      fleetSlug: fleetSlug.value,
      squadronSlug: squadronSlug.value,
      flight: flight.value,
    },
  });
};

const destroyMutation = useDestroyFleetSquadronFlight();

const onDestroy = () => {
  displayConfirm({
    text: t("messages.fleet.squadrons.flights.destroy.confirm", {
      name: flight.value?.name,
    }),
    confirmText: t("actions.delete"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          fleetSlug: fleetSlug.value,
          fleetSquadronSlug: squadronSlug.value,
          id: flightId.value,
        })
        .then(() => {
          displaySuccess({
            text: t("messages.fleet.squadrons.flights.destroy.success"),
          });
          void router.push({
            name: "fleet-squadron-flights",
            params: { slug: fleetSlug.value, squadron: squadronSlug.value },
          });
        })
        .catch(() => {
          displayAlert({
            text: t("messages.fleet.squadrons.flights.destroy.failure"),
          });
        });
    },
  });
};

const offChanged = ref<() => void>();

onMounted(() => {
  offChanged.value = comlink.on(
    "mission-children-changed",
    () => void refetch(),
  );
});

onUnmounted(() => {
  offChanged.value?.();
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: fleetSlug.value } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-squadrons", params: { slug: fleetSlug.value } },
    label: t("headlines.fleets.squadrons.index"),
  },
  ...(squadron.value
    ? [
        {
          to: {
            name: "fleet-squadron-flights",
            params: { slug: fleetSlug.value, squadron: squadron.value.slug },
          },
          label: squadron.value.name,
        },
      ]
    : []),
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Loader :loading="isLoading" />

  <template v-if="flight && squadron">
    <div class="flight-identity">
      <SquadronEmblem :squadron="squadron" :size="64" />
      <Heading hero size="hero">
        {{ flight.name }}
        <template #subHeading>
          {{
            t("labels.fleet.squadrons.flights.ofSquadron", {
              squadron: squadron.name,
            })
          }}
        </template>
      </Heading>
    </div>

    <Teleport to="#header-right">
      <Btn
        v-if="canManage"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="flight-edit"
        @click="openEditModal"
      >
        <i class="fa-duotone fa-pen" />
        {{ t("actions.edit") }}
      </Btn>
      <Btn
        v-if="canManage"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="flight-destroy"
        @click="onDestroy"
      >
        <i class="fa-duotone fa-trash" />
        {{ t("actions.delete") }}
      </Btn>
    </Teleport>

    <Markdown
      v-if="flight.description"
      class="flight-description"
      :source="flight.description"
    />

    <FlightLineup
      :fleet="props.fleet"
      :squadron="squadron"
      :flight="flight"
      :editable="canManage"
    />
  </template>
</template>

<style lang="scss" scoped>
.flight-identity {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
}

.flight-description {
  max-width: 72ch;
  margin-bottom: 24px;
  color: var(--color-muted, #7a8288);
}
</style>
