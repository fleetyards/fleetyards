<script lang="ts">
export default {
  name: "FleetSquadronPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Grid from "@/shared/components/base/Grid/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import MembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import FleetVehiclePanel from "@/frontend/components/Fleets/VehiclePanel/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type Fleet,
  type FleetMember,
  useFleetSquadron,
  useFleetSquadronMembers,
  useFleetSquadronVehicles,
  useFleetSquadronVehiclesStats,
  useFleetSquadronMembersStats,
  useDestroyFleetSquadron,
  getFleetSquadronVehiclesQueryKey,
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

const TABS = ["members", "ships", "stats"] as const;

type SquadronTab = (typeof TABS)[number];

// The tab lives in the query rather than in local state, so a link to a
// squadron's ships is a link somebody can send. `App.vue` keys the page on
// `locale-path`, so a path of its own would rebuild the page on every switch.
const tab = computed<SquadronTab>(() =>
  TABS.includes(route.query.tab as SquadronTab)
    ? (route.query.tab as SquadronTab)
    : "members",
);

const tabLink = (value: SquadronTab) => ({
  name: "fleet-squadron",
  params: route.params,
  query: value === "members" ? {} : { tab: value },
});

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => route.params.squadron as string);

const canUpdate = computed(
  () => props.membership?.capabilities?.updateSquadrons ?? false,
);

const canDestroy = computed(
  () => props.membership?.capabilities?.destroySquadrons ?? false,
);

const canManageMembers = computed(
  () => props.membership?.capabilities?.manageSquadronMembers ?? false,
);

const {
  data: squadron,
  isLoading: squadronLoading,
  refetch: refetchSquadron,
} = useFleetSquadron(fleetSlug, squadronSlug);

const { data: members, refetch: refetchMembers } = useFleetSquadronMembers(
  fleetSlug,
  squadronSlug,
  {},
);

const memberItems = computed(() => members.value?.items ?? []);

const vehiclesQueryKey = getFleetSquadronVehiclesQueryKey(
  props.fleet.slug,
  squadronSlug.value,
);

const { perPage, page, updatePerPage } = usePagination(vehiclesQueryKey);

const vehicleParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const {
  data: vehicles,
  isLoading: vehiclesLoading,
  refetch: refetchVehicles,
} = useFleetSquadronVehicles(fleetSlug, squadronSlug, vehicleParams);

const vehicleItems = computed(() => vehicles.value?.items ?? []);

const { data: vehicleStats, refetch: refetchVehicleStats } =
  useFleetSquadronVehiclesStats(fleetSlug, squadronSlug);

const { data: memberStats, refetch: refetchMemberStats } =
  useFleetSquadronMembersStats(fleetSlug, squadronSlug, {});

const refetchAll = async () => {
  await Promise.all([
    refetchSquadron(),
    refetchMembers(),
    refetchVehicles(),
    refetchVehicleStats(),
    refetchMemberStats(),
  ]);
};

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronModal/index.vue"),
    props: { fleet: props.fleet, squadron: squadron.value },
  });
};

const openMemberPicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronMemberPicker/index.vue"),
    props: { fleet: props.fleet, squadron: squadron.value },
  });
};

const destroyMutation = useDestroyFleetSquadron();

// Disbanding takes nobody out of the fleet, but the squadron itself does not
// come back -- hence danger rather than warning.
const onDestroy = () => {
  displayConfirm({
    text: t("messages.fleet.squadrons.destroy.confirm", {
      name: squadron.value?.name,
    }),
    confirmText: t("actions.delete"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          slug: squadronSlug.value,
        })
        .then(() => {
          displaySuccess({
            text: t("messages.fleet.squadrons.destroy.success"),
          });
          void router.push({
            name: "fleet-squadrons",
            params: { slug: props.fleet.slug },
          });
        })
        .catch(() => {
          displayAlert({
            text: t("messages.fleet.squadrons.destroy.failure"),
          });
        });
    },
  });
};

const squadronUpdatedComlink = ref();
const squadronMembersComlink = ref();

onMounted(() => {
  squadronUpdatedComlink.value = comlink.on(
    "fleet-squadron-updated",
    () => void refetchAll(),
  );
  squadronMembersComlink.value = comlink.on(
    "fleet-squadron-members-updated",
    () => void refetchAll(),
  );
});

onUnmounted(() => {
  squadronUpdatedComlink.value();
  squadronMembersComlink.value();
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-squadrons", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.squadrons.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Loader :loading="squadronLoading" />

  <template v-if="squadron">
    <Heading hero size="hero">
      {{ squadron.name }}
      <template #subHeading>
        {{
          t("labels.fleet.squadrons.memberCount", {
            count: squadron.memberCount,
          })
        }}
      </template>
    </Heading>

    <p v-if="squadron.description" class="squadron-description text-muted">
      {{ squadron.description }}
    </p>

    <Teleport to="#header-right">
      <Btn
        v-if="canManageMembers"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-add-member"
        @click="openMemberPicker"
      >
        <i class="fa-duotone fa-user-plus" />
        {{ t("actions.fleet.squadrons.addMember") }}
      </Btn>
      <Btn
        v-if="canUpdate"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-edit"
        @click="openEditModal"
      >
        <i class="fa-duotone fa-pen" />
        {{ t("actions.edit") }}
      </Btn>
      <Btn
        v-if="canDestroy"
        :size="BtnSizesEnum.MD"
        mobile-icon-only
        data-test="squadron-destroy"
        @click="onDestroy"
      >
        <i class="fa-duotone fa-trash" />
        {{ t("actions.delete") }}
      </Btn>
    </Teleport>

    <BtnGroup segmented>
      <Btn
        v-for="value in TABS"
        :key="value"
        :to="tabLink(value)"
        :active="tab === value"
        :data-test="`squadron-tab-${value}`"
        mobile-icon-only
      >
        {{ t(`labels.fleet.squadrons.tabs.${value}`) }}
      </Btn>
    </BtnGroup>

    <template v-if="tab === 'members'">
      <MembersList
        :members="memberItems"
        :capabilities="props.membership?.capabilities"
        :empty-visible="!memberItems.length"
        :show-squadrons="false"
      />
    </template>

    <template v-else-if="tab === 'ships'">
      <Loader :loading="vehiclesLoading" />

      <Paginator
        v-if="vehicleItems.length"
        :query-result-ref="vehicles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />

      <Grid v-if="vehicleItems.length" :records="vehicleItems" primary-key="id">
        <template #default="{ record }">
          <FleetVehiclePanel
            :fleet-slug="props.fleet.slug"
            :fleet-vehicle="record"
          />
        </template>
      </Grid>

      <Empty
        v-else-if="!vehiclesLoading"
        :name="t('labels.fleet.squadrons.ships')"
        data-test="squadron-ships-empty"
      />
    </template>

    <template v-else>
      <div class="row">
        <div class="col-12 col-md-6 col-lg-3">
          <StatsPanel
            :label="t('labels.fleet.squadrons.stats.members')"
            icon="fa-duotone fa-users"
            :value="memberStats?.total ?? 0"
          />
        </div>
        <div class="col-12 col-md-6 col-lg-3">
          <StatsPanel
            :label="t('labels.fleet.squadrons.stats.ships')"
            icon="fa-duotone fa-starship"
            :value="vehicleStats?.total ?? 0"
          />
        </div>
        <div class="col-12 col-md-6 col-lg-3">
          <StatsPanel
            :label="t('labels.fleet.squadrons.stats.uniqueModels')"
            icon="fa-duotone fa-rocket-launch"
            :value="vehicleStats?.metrics?.uniqueModelsCount ?? 0"
          />
        </div>
        <div class="col-12 col-md-6 col-lg-3">
          <StatsPanel
            :label="t('labels.fleet.squadrons.stats.totalMoney')"
            icon="fa-duotone fa-dollar-sign"
            :value="vehicleStats?.metrics?.totalMoney ?? 0"
            :prefix="t('number.units.currency')"
          />
        </div>
      </div>
    </template>
  </template>

  <Empty
    v-else-if="!squadronLoading"
    :name="t('labels.fleet.squadrons.index')"
  />
</template>

<style lang="scss" scoped>
.squadron-description {
  margin-bottom: 20px;
}
</style>
