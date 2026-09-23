<script lang="ts">
export default {
  name: "FleetSquadronMembersPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FleetMembersFilterForm from "@/frontend/components/Fleets/MembersFilterForm/index.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  useFleetMembers as useFleetMembersQuery,
  useFleetSquadron,
  useDestroyFleetSquadronMember,
  getFleetMembersQueryKey,
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
const route = useRoute();
const comlink = useComlink();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);
const squadronSlug = computed(() => route.params.squadron as string);

const { data: squadron, isLoading: squadronLoading } = useFleetSquadron(
  fleetSlug,
  squadronSlug,
);

const canManageMembers = computed(
  () => props.membership?.capabilities?.manageSquadronMembers ?? false,
);

const { isFilterSelected, getQuery } = useFilters<FleetMemberQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const { perPage, page, updatePerPage } = usePagination(
  getFleetMembersQueryKey(props.fleet.slug),
);

/*
 * The fleet's roster with the squadron fixed, rather than a list of its own:
 * the filter, the columns and the presence are the roster's, and a second
 * implementation of them would drift. The scope is not a filter anybody can
 * clear -- it is what this page is.
 */
const membersQueryParams = computed<FleetMembersParams>(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    ...getQuery(),
    squadronSlugIn: [squadronSlug.value],
    stateIn: ["accepted"],
  } as FleetMemberQuery,
}));

const {
  data: members,
  refetch,
  ...asyncStatus
} = useFleetMembersQuery(fleetSlug, membersQueryParams);

const memberItems = computed(() => members.value?.items ?? []);

const destroyMutation = useDestroyFleetSquadronMember();

// Out of the squadron, not out of the fleet -- which is the confusion worth
// heading off, since this row looks like the roster's.
const removeMember = (member: FleetMember) => {
  displayConfirm({
    text: t("messages.fleet.squadrons.members.destroy.confirm", {
      username: member.username,
      squadron: squadron.value?.name,
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

const openMemberPicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Squadrons/SquadronMemberPicker/index.vue"),
    props: { fleet: props.fleet, squadron: squadron.value },
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

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-squadrons", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.squadrons.index"),
  },
  ...(squadron.value
    ? [
        {
          to: {
            name: "fleet-squadron",
            params: { slug: props.fleet.slug, squadron: squadron.value.slug },
          },
          label: squadron.value.name,
        },
      ]
    : []),
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Loader :loading="squadronLoading" />

  <Heading hero size="hero">
    {{ t("headlines.fleets.squadrons.members") }}
    <template v-if="squadron" #subHeading>
      {{ squadron.name }}
    </template>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      v-if="canManageMembers && squadron"
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      data-test="squadron-add-member"
      @click="openMemberPicker"
    >
      <i class="fa-duotone fa-user-plus" />
      {{ t("actions.fleet.squadrons.addMember") }}
    </Btn>
  </Teleport>

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
      <FleetMembersFilterForm variant="members" />
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
      >
        <template v-if="canManageMembers" #row-actions="{ member }">
          <Btn
            v-tooltip="t('actions.fleet.squadrons.removeMember')"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('actions.fleet.squadrons.removeMember')"
            :data-test="`squadron-remove-${member.username}`"
            @click="removeMember(member)"
          >
            <i class="fa-duotone fa-user-minus" />
          </Btn>
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
