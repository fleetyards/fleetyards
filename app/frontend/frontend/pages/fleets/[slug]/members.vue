<script lang="ts">
export default {
  name: "FleetMembersPage",
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
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import { useFilters } from "@/shared/composables/useFilters";
import {
  useFleetMembersStats as useFleetMembersStatsQuery,
  useFleetMembers as useFleetMembersQuery,
  type Fleet,
  type FleetMember,
  type FleetMemberQuery,
  type FleetMembersParams,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const mobile = useMobile();

const route = useRoute();

const canInvite = computed(() =>
  ["admin", "officer"].includes(props.membership.fleetRole.name),
);

const { isFilterSelected, getQuery } = useFilters<FleetMemberQuery>({
  allowedKeys: ["usernameCont", "roleIn", "sorts"],
  updateCallback: async () => {
    await refetch();
  },
});

const membersQueryParams = computed<FleetMembersParams>(() => ({
  page: route.query.page as string | undefined,
  q: getQuery() as FleetMemberQuery,
}));

const {
  data: members,
  refetch,
  ...asyncStatus
} = useFleetMembersQuery(props.fleet.slug, membersQueryParams);

const { data: stats, refetch: refetchStats } = useFleetMembersStatsQuery(
  props.fleet.slug,
);

const fetch = async () => {
  await refetch();
  await refetchStats();
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
  <Heading>
    {{ t("headlines.fleets.members") }}
    <small v-if="stats" class="text-muted">
      {{
        t("labels.fleet.members.total", {
          count: stats.total,
        })
      }}
    </small>
  </Heading>

  <Teleport v-if="!mobile && canInvite" to="#header-right">
    <Btn :inline="true" @click="openInviteUrlModal">
      <i class="fal fa-plus" />
      {{ t("actions.fleet.createInviteUrl") }}
    </Btn>
    <Btn :inline="true" @click="openInviteModal">
      <i class="fad fa-user-plus" />
      {{ t("actions.fleet.inviteMember") }}
    </Btn>
  </Teleport>

  <FilteredList
    key="fleet-members"
    :records="members || []"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template v-if="mobile && canInvite" #actions-right>
      <BtnDropdown :size="BtnSizesEnum.SMALL">
        <Btn :size="BtnSizesEnum.SMALL" @click="openInviteUrlModal">
          <i class="fal fa-plus" />
          <span>{{ t("actions.fleet.createInviteUrl") }}</span>
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" @click="openInviteModal">
          <i class="fad fa-user-plus" />
          <span>{{ t("actions.fleet.inviteMember") }}</span>
        </Btn>
      </BtnDropdown>
    </template>

    <template #filter>
      <FleetMembersFilterForm />
    </template>

    <template #default="{ records }">
      <FleetMembersList
        :members="records"
        :role="membership.fleetRole.name as 'admin' | 'officer' | 'member'"
      />
    </template>
  </FilteredList>
</template>
