<script lang="ts">
export default {
  name: "CatalogueItemPopover",
};
</script>

<script lang="ts" setup>
import BasePopover from "@/shared/components/Popover/index.vue";
import ComponentStatsCard from "@/frontend/components/StatsCard/Component/index.vue";
import EquipmentStatsCard from "@/frontend/components/StatsCard/Equipment/index.vue";
import CommodityStatsCard from "@/frontend/components/StatsCard/Commodity/index.vue";
import ShipStatsCard from "@/frontend/components/StatsCard/Ship/index.vue";
import BlueprintStatsCard from "@/frontend/components/StatsCard/Blueprint/index.vue";
import MissionStatsCard from "@/frontend/components/StatsCard/Mission/index.vue";
import ContractStatsCard from "@/frontend/components/StatsCard/Contract/index.vue";
import EventStatsCard from "@/frontend/components/StatsCard/Event/index.vue";
import UserStatsCard from "@/frontend/components/StatsCard/User/index.vue";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import {
  useComponent as useComponentQuery,
  useEquipmentItem as useEquipmentItemQuery,
  useCommodity as useCommodityQuery,
  useModel as useModelQuery,
  useBlueprint as useBlueprintQuery,
  useGameMission as useGameMissionQuery,
  useFleetContract as useFleetContractQuery,
  useFleetEvent as useFleetEventQuery,
  usePublicUser as usePublicUserQuery,
  type Blueprint,
  type Commodity,
  type Component,
  type Equipment,
  type FleetContractDetail,
  type FleetEvent,
  type GameMission,
  type Model,
  type UserPublic,
} from "@/services/fyApi";
import { type CatalogueItemRef, type CatalogueRecord } from "./types";

type Props = {
  item: CatalogueItemRef;
  // The record itself, where the page already holds it -- a hardpoint row has
  // its component, a catalogue row its item. Without one the card is fetched.
  record?: CatalogueRecord;
  // Off where the trigger already sits inside a link to the same record, such
  // as a list row's name: an anchor inside an anchor does not work.
  link?: boolean;
  linkClass?: string;
  // For a trigger with no text of its own, such as an icon.
  linkLabel?: string;
  // Off for the same list-row name: the row's own link is the focus stop.
  focusable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  record: undefined,
  link: true,
  linkClass: undefined,
  linkLabel: undefined,
  focusable: true,
});

const route = computed(() => catalogueItemRoute(props.item));

const slug = computed(() => props.item.slug || "");
const fleetSlug = computed(() => props.item.fleetSlug || "");

const isComponent = computed(() => props.item.type === "Component");
const isEquipment = computed(() => props.item.type === "Equipment");
const isCommodity = computed(() => props.item.type === "Commodity");
const isShip = computed(() => props.item.type === "Model");
const isBlueprint = computed(() => props.item.type === "Blueprint");
const isMission = computed(() => props.item.type === "GameMission");
const isContract = computed(() => props.item.type === "FleetContract");
const isEvent = computed(() => props.item.type === "FleetEvent");
const isUser = computed(() => props.item.type === "User");

// Fetched the first time the card opens -- never for every link on a page --
// and left enabled afterwards, so the query cache (shared with the detail
// pages) answers every later open.
//
// The card only renders once it has opened, when its query is enabled, so
// `isPending` means the answer is still to come. A failed request leaves
// pending without data, which the card states rather than spinning on.
const requested = ref(false);

const fetches = (type: Ref<boolean>) =>
  computed(
    () => requested.value && type.value && !props.record && !!slug.value,
  );

const fetchesInFleet = (type: Ref<boolean>) =>
  computed(() => fetches(type).value && !!fleetSlug.value);

const { data: fetchedComponent, isPending: componentPending } =
  useComponentQuery(slug, { query: { enabled: fetches(isComponent) } });

const { data: fetchedEquipment, isPending: equipmentPending } =
  useEquipmentItemQuery(slug, { query: { enabled: fetches(isEquipment) } });

const { data: fetchedCommodity, isPending: commodityPending } =
  useCommodityQuery(slug, { query: { enabled: fetches(isCommodity) } });

const { data: fetchedShip, isPending: shipPending } = useModelQuery(slug, {
  query: { enabled: fetches(isShip) },
});

const { data: fetchedBlueprint, isPending: blueprintPending } =
  useBlueprintQuery(slug, { query: { enabled: fetches(isBlueprint) } });

const { data: fetchedMission, isPending: missionPending } = useGameMissionQuery(
  slug,
  { query: { enabled: fetches(isMission) } },
);

const { data: fetchedContract, isPending: contractPending } =
  useFleetContractQuery(fleetSlug, slug, {
    query: { enabled: fetchesInFleet(isContract) },
  });

const { data: fetchedEvent, isPending: eventPending } = useFleetEventQuery(
  fleetSlug,
  slug,
  undefined,
  { query: { enabled: fetchesInFleet(isEvent) } },
);

const { data: fetchedUser, isPending: userPending } = usePublicUserQuery(slug, {
  query: { enabled: fetches(isUser) },
});

const component = computed(
  () => (props.record as Component | undefined) ?? fetchedComponent.value,
);
const equipment = computed(
  () => (props.record as Equipment | undefined) ?? fetchedEquipment.value,
);
const commodity = computed(
  () => (props.record as Commodity | undefined) ?? fetchedCommodity.value,
);

const ship = computed(
  () => (props.record as Model | undefined) ?? fetchedShip.value,
);
const blueprint = computed(
  () => (props.record as Blueprint | undefined) ?? fetchedBlueprint.value,
);
const mission = computed(
  () => (props.record as GameMission | undefined) ?? fetchedMission.value,
);
const contract = computed(
  () =>
    (props.record as FleetContractDetail | undefined) ?? fetchedContract.value,
);
const event = computed(
  () => (props.record as FleetEvent | undefined) ?? fetchedEvent.value,
);
const user = computed(
  () => (props.record as UserPublic | undefined) ?? fetchedUser.value,
);

const pending = (type: Ref<boolean>, isPending: Ref<boolean>) =>
  computed(() => !props.record && type.value && isPending.value);

const componentLoading = pending(isComponent, componentPending);
const equipmentLoading = pending(isEquipment, equipmentPending);
const commodityLoading = pending(isCommodity, commodityPending);
const shipLoading = pending(isShip, shipPending);
const blueprintLoading = pending(isBlueprint, blueprintPending);
const missionLoading = pending(isMission, missionPending);
const contractLoading = pending(isContract, contractPending);
const eventLoading = pending(isEvent, eventPending);
const userLoading = pending(isUser, userPending);

// A record the catalogue does not list still has figures worth reading -- a
// door or a seat on a ship -- so a card needs a record or a page, not both.
const hasCard = computed(
  () =>
    (isComponent.value ||
      isEquipment.value ||
      isCommodity.value ||
      isShip.value ||
      isBlueprint.value ||
      isMission.value ||
      isContract.value ||
      isEvent.value ||
      isUser.value) &&
    (!!props.record || !!route.value),
);

const linked = computed(() => props.link && !!route.value);

const label = computed(() => props.item.name || props.linkLabel || "");
</script>

<template>
  <BasePopover
    v-if="hasCard"
    :label="label"
    :focusable="focusable"
    @open="requested = true"
  >
    <router-link
      v-if="linked"
      :to="route!"
      :class="linkClass"
      :aria-label="linkLabel"
      @click.stop
    >
      <slot>{{ item.name }}</slot>
    </router-link>
    <slot v-else>{{ item.name }}</slot>

    <template #content="{ close }">
      <ComponentStatsCard
        v-if="isComponent"
        compact
        :to="route ?? false"
        :name="label"
        :component="component"
        :loading="componentLoading"
        @navigate="close"
      />
      <EquipmentStatsCard
        v-else-if="isEquipment"
        compact
        :to="route ?? false"
        :name="label"
        :equipment="equipment"
        :loading="equipmentLoading"
        @navigate="close"
      />
      <ShipStatsCard
        v-else-if="isShip"
        :to="route ?? false"
        :name="label"
        :model="ship"
        :loading="shipLoading"
        @navigate="close"
      />
      <BlueprintStatsCard
        v-else-if="isBlueprint"
        :to="route ?? false"
        :name="label"
        :blueprint="blueprint"
        :loading="blueprintLoading"
        @navigate="close"
      />
      <MissionStatsCard
        v-else-if="isMission"
        :to="route ?? false"
        :name="label"
        :mission="mission"
        :loading="missionLoading"
        @navigate="close"
      />
      <ContractStatsCard
        v-else-if="isContract"
        :to="route ?? false"
        :name="label"
        :contract="contract"
        :loading="contractLoading"
        @navigate="close"
      />
      <EventStatsCard
        v-else-if="isEvent"
        :to="route ?? false"
        :name="label"
        :event="event"
        :loading="eventLoading"
        @navigate="close"
      />
      <UserStatsCard
        v-else-if="isUser"
        :to="route ?? false"
        :name="label"
        :user="user"
        :loading="userLoading"
        @navigate="close"
      />
      <CommodityStatsCard
        v-else
        compact
        :to="route ?? false"
        :name="label"
        :commodity="commodity"
        :loading="commodityLoading"
        @navigate="close"
      />
    </template>
  </BasePopover>

  <router-link
    v-else-if="linked"
    :to="route!"
    :class="linkClass"
    :aria-label="linkLabel"
    @click.stop
  >
    <slot>{{ item.name }}</slot>
  </router-link>

  <template v-else>
    <slot>{{ item.name }}</slot>
  </template>
</template>
