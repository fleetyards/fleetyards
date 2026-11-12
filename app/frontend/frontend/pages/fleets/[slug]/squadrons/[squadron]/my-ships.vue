<script lang="ts">
export default {
  name: "FleetSquadronMyShipsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Loader from "@/shared/components/Loader/index.vue";
import ShipRequestsList from "@/frontend/components/Fleets/Squadrons/ShipRequestsList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import { useHangarGroups } from "@/services/fyApi/services/hangar-groups/hangar-groups";
import {
  type FilterOption,
  type Fleet,
  type FleetMember,
  type FleetSquadron,
  type VehiclePublic,
  FleetSquadronShipsFilterEnum,
  useFleetSquadronShipSelection,
  useFleetVehicles,
  useUpdateFleetSquadronShipSelection,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const sessionStore = useSessionStore();

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => props.squadron.slug);
const username = computed(() => sessionStore.currentUser?.username);
const isMember = computed(() => !!props.squadron.viewerIsMember);

const {
  data: selection,
  isLoading,
  refetch,
} = useFleetSquadronShipSelection(fleetSlug, squadronSlug, {
  query: { enabled: isMember },
});

// What the reader shares with the fleet -- the most the squadron can get.
const { data: fleetShips } = useFleetVehicles(
  fleetSlug,
  computed(() => ({ perPage: "240", q: { memberIn: [username.value ?? ""] } })),
  { query: { enabled: computed(() => isMember.value && !!username.value) } },
);

const ships = computed(() =>
  ((fleetShips.value?.items ?? []) as VehiclePublic[]).filter(
    (vehicle) => !vehicle.loaner,
  ),
);

const { data: hangarGroups } = useHangarGroups({
  query: { enabled: isMember },
});

const shipsFilter = ref<FleetSquadronShipsFilterEnum>(
  FleetSquadronShipsFilterEnum.ALL,
);
const hangarGroupId = ref<string | null>(null);
const pickedIds = ref<string[]>([]);

watch(
  selection,
  (value) => {
    if (!value) return;

    shipsFilter.value = value.shipsFilter;
    hangarGroupId.value = value.hangarGroupId ?? null;
    pickedIds.value = [...value.vehicleIds];
  },
  { immediate: true },
);

const filterOptions = computed<FilterOption[]>(() => [
  {
    label: t("labels.fleet.squadrons.shipsFilter.all"),
    value: FleetSquadronShipsFilterEnum.ALL,
  },
  {
    label: t("labels.fleet.squadrons.shipsFilter.hangar_group"),
    value: FleetSquadronShipsFilterEnum.HANGAR_GROUP,
  },
  {
    label: t("labels.fleet.squadrons.shipsFilter.picked"),
    value: FleetSquadronShipsFilterEnum.PICKED,
  },
]);

const hangarGroupOptions = computed<FilterOption[]>(() =>
  (hangarGroups.value ?? []).map((group) => ({
    label: group.name,
    value: group.id,
  })),
);

// Picked ships ride on top of a hangar group as well -- which is where a ship
// an officer asked for and the reader gave lands.
const showPicks = computed(
  () => shipsFilter.value !== FleetSquadronShipsFilterEnum.ALL,
);

const isPicked = (id: string) => pickedIds.value.includes(id);

const togglePick = (id: string) => {
  pickedIds.value = isPicked(id)
    ? pickedIds.value.filter((held) => held !== id)
    : [...pickedIds.value, id];
};

const shipLabel = (vehicle: VehiclePublic) =>
  vehicle.name
    ? `${vehicle.name} (${vehicle.model?.name})`
    : vehicle.model?.name;

const mutation = useUpdateFleetSquadronShipSelection();

const onSubmit = async () => {
  await mutation
    .mutateAsync({
      fleetSlug: fleetSlug.value,
      fleetSquadronSlug: squadronSlug.value,
      data: {
        shipsFilter: shipsFilter.value,
        hangarGroupId:
          shipsFilter.value === FleetSquadronShipsFilterEnum.HANGAR_GROUP
            ? hangarGroupId.value
            : null,
        vehicleIds: pickedIds.value,
      },
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleet.squadrons.shipSelection.update.success"),
      });
    })
    .catch((error) => {
      displayAlert({
        text:
          firstErrorMessageFrom(error) ??
          t("messages.fleet.squadrons.shipSelection.update.failure"),
      });
    });
};
</script>

<template>
  <ShipRequestsList
    :fleet-slug="fleetSlug"
    :squadron-slug="squadronSlug"
    :username="username"
    @accepted="refetch"
  />

  <p v-if="!isMember" class="text-muted" data-test="my-ships-not-member">
    {{ t("texts.fleet.squadrons.myShipsNotMember") }}
  </p>

  <template v-else>
    <Loader v-if="isLoading" :loading="true" inline />

    <form v-else class="my-ships" @submit.prevent="onSubmit">
      <Heading :level="HeadingLevelEnum.H3">
        {{ t("headlines.fleets.squadrons.myShips") }}
      </Heading>
      <p class="text-muted">
        {{ t("texts.fleet.squadrons.myShipsHint") }}
      </p>

      <BaseSelect
        v-model="shipsFilter"
        name="shipsFilter"
        :label="t('labels.fleet.squadrons.shipsFilter.label')"
        :options="filterOptions"
        unsorted
      />

      <BaseSelect
        v-if="shipsFilter === FleetSquadronShipsFilterEnum.HANGAR_GROUP"
        v-model="hangarGroupId"
        name="hangarGroupId"
        :label="t('labels.fleet.squadrons.shipsFilter.hangarGroup')"
        :options="hangarGroupOptions"
      />

      <fieldset v-if="showPicks" class="my-ships__picks">
        <legend>
          {{
            shipsFilter === FleetSquadronShipsFilterEnum.PICKED
              ? t("labels.fleet.squadrons.shipsFilter.pickedShips")
              : t("labels.fleet.squadrons.shipsFilter.extraShips")
          }}
        </legend>
        <label
          v-for="vehicle in ships"
          :key="vehicle.id"
          class="my-ships__pick"
          :data-test="`my-ships-pick-${vehicle.id}`"
        >
          <input
            type="checkbox"
            :checked="isPicked(vehicle.id)"
            @change="togglePick(vehicle.id)"
          />
          <span>{{ shipLabel(vehicle) }}</span>
        </label>
        <p v-if="!ships.length" class="text-muted">
          {{ t("texts.fleet.squadrons.myShipsNoneShared") }}
        </p>
      </fieldset>

      <div class="my-ships__actions">
        <Btn
          type="submit"
          :loading="mutation.isPending.value"
          data-test="my-ships-save"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </form>
  </template>
</template>

<style lang="scss" scoped>
.my-ships {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 640px;
}

.my-ships__picks {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 6px 16px;
  margin: 0;
  padding: 12px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);

  legend {
    padding: 0 6px;
    font-size: 0.8125rem;
    color: var(--color-muted, #7a8288);
  }
}

.my-ships__pick {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.my-ships__actions {
  display: flex;
  justify-content: flex-end;
}
</style>
