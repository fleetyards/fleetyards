<script lang="ts">
export default {
  name: "FleetSquadronMembersPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import SquadronMembersFilterForm from "@/frontend/components/Fleets/Squadrons/SquadronMembersFilterForm/index.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  outranks,
  rankOptionsFor,
  type SquadronRankViewer,
} from "@/frontend/utils/squadronRanks";
import {
  useFleetSquadronMembers,
  useFleetSquadronRoles,
  useDestroyFleetSquadronMember,
  getFleetSquadronMembersQueryKey,
  type Fleet,
  type FleetMember,
  type FleetSquadronMemberQuery,
  type FleetSquadronMembersParams,
  type FleetSquadron,
  type FleetSquadronRole,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const comlink = useComlink();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => route.params.squadron as string);

const fleetWide = computed(
  () => props.membership?.capabilities?.manageSquadronMembers ?? false,
);

const canManageMembers = computed(
  () => props.squadron.capabilities?.manageMembers ?? fleetWide.value,
);

const canManageRanks = computed(
  () => props.squadron.capabilities?.manageRanks ?? fleetWide.value,
);

const viewerRole = computed(() => props.squadron.viewerRole);

const { data: ranks } = useFleetSquadronRoles(fleetSlug);

const { isFilterSelected, getQuery } = useFilters<FleetSquadronMemberQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const { perPage, page, updatePerPage } = usePagination(
  getFleetSquadronMembersQueryKey(props.fleet.slug, squadronSlug.value),
);

/*
 * The squadron's own roster endpoint, which renders the fleet's member rows
 * with the fleet's filters: the columns and the presence are the roster's, and
 * a second implementation of them would drift. It is also the one list that
 * can sort by when somebody joined this squadron -- across the whole fleet a
 * member has no single answer to that.
 */
const membersQueryParams = computed<FleetSquadronMembersParams>(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery() as FleetSquadronMemberQuery,
}));

const {
  data: members,
  refetch,
  ...asyncStatus
} = useFleetSquadronMembers(fleetSlug, squadronSlug, membersQueryParams);

const memberItems = computed(() => members.value?.items ?? []);

const destroyMutation = useDestroyFleetSquadronMember();

const entryFor = (member: FleetMember) =>
  member.squadrons?.find((item) => item.slug === squadronSlug.value);

const isSelf = (member: FleetMember) =>
  member.username === props.membership?.username;

const rankViewer = computed<SquadronRankViewer>(() => ({
  fleetWide: fleetWide.value,
  viewerRole: viewerRole.value,
  canManageRanks: canManageRanks.value,
}));

const outranksMember = (member: FleetMember) =>
  outranks(rankViewer.value, entryFor(member)?.role);

const rankOptionsForMember = (member: FleetMember): FleetSquadronRole[] =>
  rankOptionsFor(rankViewer.value, ranks.value ?? [], {
    rank: entryFor(member)?.role,
    isSelf: isSelf(member),
  });

// The rank select fills in once the ranks are in; until then, or if they fail
// to load, the modal still edits the join date.
const canEdit = (member: FleetMember) =>
  !!entryFor(member) &&
  (outranksMember(member) || rankOptionsForMember(member).length > 1);

const openEditModal = (member: FleetMember) => {
  const entry = entryFor(member);
  if (!entry) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronMemberEditModal/index.vue"),
    props: {
      fleetSlug: props.fleet.slug,
      squadronSlug: squadronSlug.value,
      username: member.username,
      membershipCreatedAt: entry.membershipCreatedAt ?? undefined,
      roleId: entry.role?.id,
      rankOptions: rankOptionsForMember(member),
      dateEditable: outranksMember(member),
    },
  });
};

// Out of the squadron, not out of the fleet -- which is the confusion worth
// heading off, since this row looks like the roster's.
const removeMember = (member: FleetMember) => {
  displayConfirm({
    text: t("messages.fleet.squadrons.members.destroy.confirm", {
      username: member.username,
      squadron: props.squadron.name,
    }),
    confirmText: t("actions.remove"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          fleetSquadronSlug: squadronSlug.value,
          username: member.username as string,
        })
        .then(async () => {
          displaySuccess({
            text: t("messages.fleet.squadrons.members.destroy.success"),
          });
          comlink.emit("fleet-squadron-members-updated");
          await refetch();
        })
        .catch(() => {
          displayAlert({
            text: t("messages.fleet.squadrons.members.destroy.failure"),
          });
        });
    },
  });
};

const membersAddedComlink = ref<() => void>();

onMounted(() => {
  membersAddedComlink.value = comlink.on(
    "fleet-squadron-members-updated",
    () => void refetch(),
  );
});

onUnmounted(() => {
  membersAddedComlink.value?.();
});
</script>

<template>
  <FilteredList
    key="fleet-squadron-members"
    :records="memberItems"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
    hide-empty
    placeholders
  >
    <template #filter>
      <SquadronMembersFilterForm />
    </template>

    <template #default="{ emptyVisible, loading }">
      <!-- The squadron badge is off: every row on this page carries the same
           one, so it would say nothing. -->
      <FleetMembersList
        :members="memberItems"
        :capabilities="props.membership?.capabilities"
        :empty-visible="emptyVisible"
        :loading="loading"
        :show-squadrons="false"
        :show-member-actions="false"
        :squadron-slug="squadronSlug"
      >
        <template v-if="canManageMembers" #row-actions="{ member }">
          <BtnGroup>
            <Btn
              v-if="canEdit(member)"
              v-tooltip="t('actions.edit')"
              :variant="BtnVariantsEnum.BARE"
              :aria-label="t('actions.edit')"
              :data-test="`squadron-member-edit-${member.username}`"
              @click="openEditModal(member)"
            >
              <i class="fa-duotone fa-user-pen" />
            </Btn>
            <Btn
              v-if="outranksMember(member)"
              v-tooltip="t('actions.fleet.squadrons.removeMember')"
              :variant="BtnVariantsEnum.BARE"
              :aria-label="t('actions.fleet.squadrons.removeMember')"
              :data-test="`squadron-remove-${member.username}`"
              @click="removeMember(member)"
            >
              <i class="fa-duotone fa-user-minus" />
            </Btn>
          </BtnGroup>
        </template>
      </FleetMembersList>
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
