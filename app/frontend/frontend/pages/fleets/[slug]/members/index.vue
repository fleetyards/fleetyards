<script lang="ts">
export default {
  name: "FleetMembersIndexPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import debounce from "lodash.debounce";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useFilters } from "@/shared/composables/useFilters";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import {
  useFleetMembers as useFleetMembersQuery,
  useFleetMembersStats as useFleetMembersStatsQuery,
  getFleetMembersQueryKey,
  FeatureFlagName,
  type Fleet,
  type FleetMember,
  type FleetMemberQuery,
  type FleetMembersParams,
  type FleetMembersStatsParams,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const comlink = useComlink();

const canManageInvites = computed(
  () => props.membership?.capabilities?.readMembers ?? false,
);

const { isFleetFeatureEnabled } = useFeatures();
const starmapEnabled = computed(() =>
  isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_STARMAP),
);
const worldmapEnabled = computed(() =>
  isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_WORLDMAP),
);

const { isFilterSelected, getQuery } = useFilters<FleetMemberQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const fleetMembersQueryKey = getFleetMembersQueryKey(props.fleet.slug);

const { perPage, page, updatePerPage } = usePagination(fleetMembersQueryKey);

const membersQueryParams = computed<FleetMembersParams>(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    ...getQuery(),
    stateIn: ["accepted"],
  } as FleetMemberQuery,
}));

const {
  data: members,
  refetch,
  ...asyncStatus
} = useFleetMembersQuery(props.fleet.slug, membersQueryParams);

const memberItems = computed(() => members.value?.items || []);

const statsQueryParams = computed<FleetMembersStatsParams>(() => ({
  q: {
    stateIn: ["accepted"],
  } as FleetMemberQuery,
}));

const { data: stats, refetch: refetchStats } = useFleetMembersStatsQuery(
  props.fleet.slug,
  statsQueryParams,
);

const fetch = async () => {
  await Promise.all([refetch(), refetchStats()]);
};

watch(
  () => route.query.q,
  async () => {
    await fetch();
  },
);

const fleetMemberUpdateComlink = ref();

onMounted(() => {
  fleetMemberUpdateComlink.value = comlink.on("fleet-member-update", fetch);
});

onUnmounted(() => {
  fleetMemberUpdateComlink.value();
});

useSubscription({
  channelName: ChannelsEnum.FLEET_MEMBERS_CHANNEL,
  received: () => debounce(fetch, 500),
});

const crumbs = computed<Crumb[]>(() => {
  return [
    {
      to: {
        name: "fleet",
        params: {
          slug: props.fleet.slug,
        },
      },
      label: props.fleet.name,
    },
  ];
});
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero size="hero">
    {{ t("headlines.fleets.members.index") }}
    <template v-if="stats" #subHeading>
      {{
        t("labels.fleet.members.total", {
          count: stats.total,
        })
      }}
    </template>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      v-if="worldmapEnabled"
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      :to="{ name: 'fleet-members-worldmap', params: { slug: fleet.slug } }"
    >
      <i class="fa-duotone fa-globe" />
      {{ t("actions.fleet.worldmap") }}
    </Btn>
    <Btn
      v-if="starmapEnabled"
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      :to="{ name: 'fleet-members-starmap', params: { slug: fleet.slug } }"
    >
      <i class="fa-duotone fa-planet-ringed" />
      {{ t("actions.fleet.starmap") }}
    </Btn>
    <Btn
      v-if="canManageInvites"
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      :to="{ name: 'fleet-members-invites', params: { slug: fleet.slug } }"
    >
      <i class="fa-duotone fa-user-plus" />
      {{ t("actions.fleet.manageInvites") }}
    </Btn>
  </Teleport>

  <FilteredList
    key="fleet-members-index"
    :records="memberItems"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
    hide-empty
  >
    <template #filter>
      <FleetMembersFilterForm variant="members" />
    </template>

    <template #default="{ emptyVisible }">
      <FleetMembersList
        :members="memberItems"
        :capabilities="props.membership?.capabilities"
        :empty-visible="emptyVisible"
      />
    </template>

    <template #pagination-top>
      <Paginator
        v-if="members"
        :query-result-ref="members"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        v-if="members"
        :query-result-ref="members"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
