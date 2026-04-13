<script lang="ts">
export default {
  name: "FleetMembersIndexPage",
};
</script>

<script lang="ts" setup>
import debounce from "lodash.debounce";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useFilters } from "@/shared/composables/useFilters";
import { checkAccess } from "@/shared/utils/Access";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import {
  useFleetMembers as useFleetMembersQuery,
  useFleetMembersStats as useFleetMembersStatsQuery,
  getFleetMembersQueryKey,
  type Fleet,
  type FleetMember,
  type FleetMemberQuery,
  type FleetMembersParams,
  type FleetMembersStatsParams,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const comlink = useComlink();

const mobile = useMobile();

const canManageInvites = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:memberships:read",
    "fleet:memberships:manage",
    "fleet:manage",
  ]),
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
  channelName: ChannelsEnum.FLEET_MEMBERS,
  received: () => debounce(fetch, 500),
});

const crumbs = computed(() => {
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
  <Heading>
    {{ t("headlines.fleets.members.index") }}
    <small v-if="stats" class="text-muted">
      {{
        t("labels.fleet.members.total", {
          count: stats.total,
        })
      }}
    </small>
  </Heading>

  <Teleport v-if="!mobile" to="#header-right">
    <Btn
      :inline="true"
      :to="{ name: 'fleet-members-worldmap', params: { slug: fleet.slug } }"
    >
      <i class="fa-duotone fa-globe" />
      {{ t("actions.fleet.worldmap") }}
    </Btn>
    <Btn
      :inline="true"
      :to="{ name: 'fleet-members-starmap', params: { slug: fleet.slug } }"
    >
      <i class="fa-duotone fa-planet-ringed" />
      {{ t("actions.fleet.starmap") }}
    </Btn>
    <Btn
      v-if="canManageInvites"
      :inline="true"
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
    <template v-if="mobile" #actions-right>
      <Btn
        :to="{ name: 'fleet-members-worldmap', params: { slug: fleet.slug } }"
      >
        <i class="fa-duotone fa-globe" />
        <span>{{ t("actions.fleet.worldmap") }}</span>
      </Btn>
      <Btn
        :to="{ name: 'fleet-members-starmap', params: { slug: fleet.slug } }"
      >
        <i class="fa-duotone fa-planet-ringed" />
        <span>{{ t("actions.fleet.starmap") }}</span>
      </Btn>
      <Btn
        v-if="canManageInvites"
        :to="{ name: 'fleet-members-invites', params: { slug: fleet.slug } }"
      >
        <i class="fa-duotone fa-user-plus" />
        <span>{{ t("actions.fleet.manageInvites") }}</span>
      </Btn>
    </template>

    <template #filter>
      <FleetMembersFilterForm variant="members" />
    </template>

    <template #default="{ emptyVisible }">
      <FleetMembersList
        :members="memberItems"
        :resource-access="resourceAccess"
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
