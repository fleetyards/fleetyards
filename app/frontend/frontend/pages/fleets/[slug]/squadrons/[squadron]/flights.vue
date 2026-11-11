<script lang="ts">
export default {
  name: "FleetSquadronFlightsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Loader from "@/shared/components/Loader/index.vue";
import FlightSummary from "@/frontend/components/Fleets/Squadrons/FlightSummary/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetMember,
  type FleetSquadron,
  useFleetSquadronFlights,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

// Whoever arranges the roster arranges who flies together.
const canManage = computed(
  () =>
    props.squadron.capabilities?.manageMembers ??
    props.membership?.capabilities?.manageSquadronMembers ??
    false,
);

const {
  data: flights,
  isLoading,
  refetch,
} = useFleetSquadronFlights(
  computed(() => props.fleet.slug),
  computed(() => props.squadron.slug),
);

const openCreateModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/FlightModal/index.vue"),
    props: { fleetSlug: props.fleet.slug, squadronSlug: props.squadron.slug },
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
</script>

<template>
  <div class="squadron-flights">
    <div class="squadron-flights__toolbar">
      <p class="text-muted squadron-flights__hint">
        {{ t("texts.fleet.squadrons.flightsHint") }}
      </p>
      <Btn v-if="canManage" data-test="flight-create" @click="openCreateModal">
        <i class="fa-light fa-plus" />
        {{ t("actions.fleet.squadrons.flights.create") }}
      </Btn>
    </div>

    <Loader v-if="isLoading" :loading="true" inline />

    <div v-else-if="flights?.length" class="squadron-flights__list">
      <FlightSummary
        v-for="flight in flights"
        :key="flight.id"
        :flight="flight"
        :to="{
          name: 'fleet-squadron-flight',
          params: {
            slug: props.fleet.slug,
            squadron: props.squadron.slug,
            flight: flight.id,
          },
        }"
      />
    </div>

    <Empty
      v-else
      :variant="EmptyVariantsEnum.DEFAULT"
      :name="t('labels.fleet.squadrons.flights.index')"
      inline
      hide-actions
    />
  </div>
</template>

<style lang="scss" scoped>
.squadron-flights__toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}

.squadron-flights__hint {
  flex: 1;
  min-width: 240px;
  margin: 0;
}

.squadron-flights__list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 16px;
}
</style>
