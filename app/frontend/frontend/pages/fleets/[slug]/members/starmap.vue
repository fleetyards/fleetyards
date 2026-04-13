<script lang="ts">
export default {
  name: "FleetMembersStarmapPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
import MembersStarMap from "@/frontend/components/Fleets/MembersStarMap/index.vue";
import {
  useFleetMembers as useFleetMembersQuery,
  type Fleet,
  type FleetMember,
  type FleetMembersParams,
  type FleetMemberQuery,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const membersQueryParams = computed<FleetMembersParams>(() => ({
  perPage: "all",
  q: {
    stateIn: ["accepted"],
  } as FleetMemberQuery,
}));

const { data: members, ...asyncStatus } = useFleetMembersQuery(
  props.fleet.slug,
  membersQueryParams,
);

const memberItems = computed(() => members.value?.items || []);

const membersWithSystem = computed(() =>
  memberItems.value.filter((member) => member.currentSystemCode != null),
);

const crumbs = computed(() => [
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
]);
</script>

<template>
  <FeatureGuard feature="fleet_starmap">
    <BreadCrumbs :crumbs="crumbs" />
    <Heading>
      {{ t("headlines.fleets.members.starmap") }}
      <small v-if="membersWithSystem.length" class="text-muted">
        {{ membersWithSystem.length }} / {{ memberItems.length }}
      </small>
    </Heading>

    <Loader :loading="asyncStatus.isLoading.value" />

    <MembersStarMap
      v-if="!asyncStatus.isLoading.value"
      :members="memberItems"
    />
  </FeatureGuard>
</template>
