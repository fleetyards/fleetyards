<script lang="ts">
export default {
  name: "FleetMembersIndexPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import FleetInvitesList from "@/frontend/components/Fleets/InvitesList/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useFilters } from "@/shared/composables/useFilters";
import {
  useMembersView,
  type MembersView,
} from "@/frontend/composables/useMembersView";
import { useSubscription } from "@/shared/composables/useSubscription";
import { FleetMembersChannel } from "@/services/fyCable/channels/FleetMembersChannel";
import { useDebouncedRefresh } from "@/shared/composables/useDebouncedRefresh";
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
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const comlink = useComlink();

const canManageInvites = computed(
  () => props.membership?.capabilities?.readMembers ?? false,
);

const canInvite = computed(
  () => props.membership?.capabilities?.createInvites ?? false,
);

/*
 * The roster and the invites are one list asked two questions -- the same
 * endpoint, the same filter form, different states -- so they are one page,
 * with the choice in the query. In a path of its own it was a page rebuild on
 * every switch: `App.vue` keys the page on `locale-path`.
 */
const { view, views, viewQuery, scopedFilters } =
  useMembersView(canManageInvites);

const viewLink = (value: MembersView) => ({
  name: "fleet-members-index",
  params: { slug: props.fleet.slug },
  query: viewQuery(value),
});

// Everything that has not been accepted: invited, asked to join, or refused.
const INVITE_STATES = ["invited", "requested", "declined"];

const { isFilterSelected, getQuery } = useFilters<FleetMemberQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const fleetMembersQueryKey = getFleetMembersQueryKey(props.fleet.slug);

const { perPage, page, updatePerPage } = usePagination(fleetMembersQueryKey);

const stateIn = computed(() => {
  if (view.value === "members") return ["accepted"];

  const selected = getQuery().stateIn;

  return selected?.length ? selected : INVITE_STATES;
});

const membersQueryParams = computed<FleetMembersParams>(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    ...scopedFilters(getQuery()),
    stateIn: stateIn.value,
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
    stateIn: stateIn.value,
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
const fleetMemberInvitedComlink = ref();

onMounted(() => {
  fleetMemberUpdateComlink.value = comlink.on("fleet-member-update", fetch);
  // An invite lands in this list too, on the other view of it.
  fleetMemberInvitedComlink.value = comlink.on("fleet-member-invited", fetch);
});

onUnmounted(() => {
  fleetMemberUpdateComlink.value();
  fleetMemberInvitedComlink.value();
});

const refresh = useDebouncedRefresh(fetch);

useSubscription({
  channel: FleetMembersChannel,
  received: refresh,
  // The channel replays nothing it broadcast while the socket was down, so
  // the member list is read again on the way back rather than waiting for whatever
  // changes next.
  connected: ({ reconnect }) => {
    if (reconnect) {
      refresh();
    }
  },
});

const openInviteUrlModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/InviteUrlModal/index.vue"),
    props: { fleet: props.fleet },
  });
};

const openInviteModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/MemberModal/index.vue"),
    props: { fleet: props.fleet },
  });
};

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
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      :to="{ name: 'fleet-members-worldmap', params: { slug: fleet.slug } }"
    >
      <i class="fa-duotone fa-globe" />
      {{ t("actions.fleet.worldmap") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      :to="{ name: 'fleet-members-starmap', params: { slug: fleet.slug } }"
    >
      <i class="fa-duotone fa-planet-ringed" />
      {{ t("actions.fleet.starmap") }}
    </Btn>
    <template v-if="canInvite">
      <Btn :size="BtnSizesEnum.MD" mobile-icon-only @click="openInviteUrlModal">
        <i class="fa-light fa-plus" />
        {{ t("actions.fleet.createInviteUrl") }}
      </Btn>
      <Btn :size="BtnSizesEnum.MD" mobile-icon-only @click="openInviteModal">
        <i class="fa-duotone fa-user-plus" />
        {{ t("actions.fleet.inviteMember") }}
      </Btn>
    </template>
  </Teleport>

  <FilteredList
    key="fleet-members-index"
    :records="memberItems"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
    hide-empty
    placeholders
  >
    <template #filter>
      <FleetMembersFilterForm :variant="view" />
    </template>

    <!-- The roster and the invites, in the same control the boards and the
         ledger use. Only somebody who may read the invites is offered them. -->
    <template v-if="canManageInvites" #actions-left>
      <BtnGroup segmented>
        <Btn
          v-for="value in views"
          :key="value"
          :to="viewLink(value)"
          :active="view === value"
          :data-test="`members-view-${value}`"
          mobile-icon-only
        >
          <i
            class="fa-duotone"
            :class="value === 'members' ? 'fa-users' : 'fa-user-plus'"
          />
          {{ t(`labels.fleet.members.views.${value}`) }}
        </Btn>
      </BtnGroup>
    </template>

    <template #default="{ emptyVisible, loading }">
      <component
        :is="view === 'invites' ? FleetInvitesList : FleetMembersList"
        :members="memberItems"
        :capabilities="props.membership?.capabilities"
        :empty-visible="emptyVisible"
        :loading="loading"
      />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="members"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="members"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
