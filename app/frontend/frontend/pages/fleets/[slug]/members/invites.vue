<script lang="ts">
export default {
  name: "FleetMembersInvitesPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import debounce from "lodash.debounce";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
import FleetInvitesList from "@/frontend/components/Fleets/InvitesList/index.vue";

import { useFilters } from "@/shared/composables/useFilters";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import {
  useFleetMembers as useFleetMembersQuery,
  useFleetMembersStats as useFleetMembersStatsQuery,
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

const canInvite = computed(
  () => props.membership?.capabilities?.createInvites ?? false,
);

const defaultStates = ["invited", "requested", "declined"];

const { isFilterSelected, getQuery } = useFilters<FleetMemberQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const membersQueryParams = computed<FleetMembersParams>(() => {
  const query = getQuery();
  return {
    q: {
      ...query,
      stateIn: query.stateIn?.length ? query.stateIn : defaultStates,
    } as FleetMemberQuery,
  };
});

const {
  data: members,
  refetch,
  ...asyncStatus
} = useFleetMembersQuery(props.fleet.slug, membersQueryParams);

const memberItems = computed(() => members.value?.items || []);

const statsQueryParams = computed<FleetMembersStatsParams>(() => {
  const query = getQuery();
  return {
    q: {
      stateIn: query.stateIn?.length ? query.stateIn : defaultStates,
    } as FleetMemberQuery,
  };
});

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

const fleetMemberInvitedComlink = ref();
const fleetMemberUpdateComlink = ref();

onMounted(() => {
  fleetMemberInvitedComlink.value = comlink.on("fleet-member-invited", fetch);
  fleetMemberUpdateComlink.value = comlink.on("fleet-member-update", fetch);
});

onUnmounted(() => {
  fleetMemberInvitedComlink.value();
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
    {
      to: {
        name: "fleet-members-index",
        params: {
          slug: props.fleet.slug,
        },
      },
      label: t("nav.fleets.members.index"),
    },
  ];
});

const openInviteUrlModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/InviteUrlModal/index.vue"),
    props: {
      fleet: props.fleet,
    },
  });
};

const openInviteModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/MemberModal/index.vue"),
    props: {
      fleet: props.fleet,
    },
  });
};
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero size="hero">
    {{ t("headlines.fleets.invites") }}
    <template v-if="stats" #subHeading>
      {{
        t("labels.fleet.members.total", {
          count: stats.total,
        })
      }}
    </template>
  </Heading>

  <Teleport v-if="canInvite" to="#header-right">
    <Btn :size="BtnSizesEnum.MD" mobile-icon-only @click="openInviteUrlModal">
      <i class="fa-light fa-plus" />
      {{ t("actions.fleet.createInviteUrl") }}
    </Btn>
    <Btn :size="BtnSizesEnum.MD" mobile-icon-only @click="openInviteModal">
      <i class="fa-duotone fa-user-plus" />
      {{ t("actions.fleet.inviteMember") }}
    </Btn>
  </Teleport>

  <FilteredList
    key="fleet-members-invites"
    :records="memberItems"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
    hide-empty
  >
    <template #filter>
      <FleetMembersFilterForm variant="invites" />
    </template>

    <template #default="{ emptyVisible }">
      <FleetInvitesList
        :members="memberItems"
        :capabilities="props.membership?.capabilities"
        :empty-visible="emptyVisible"
      />
    </template>
  </FilteredList>
</template>
