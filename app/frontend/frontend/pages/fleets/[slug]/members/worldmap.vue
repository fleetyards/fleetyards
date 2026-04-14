<script lang="ts">
export default {
  name: "FleetMembersWorldmapPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import MembersWorldMap from "@/frontend/components/Fleets/MembersWorldMap/index.vue";
import {
  useFleetMembers as useFleetMembersQuery,
  type Fleet,
  type FleetMember,
  type FleetMembersParams,
  type FleetMemberQuery,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { isFeatureEnabled } = useFeatures();
const starmapEnabled = computed(() => isFeatureEnabled("fleet_starmap"));

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

const membersWithLocation = computed(() =>
  memberItems.value.filter(
    (member) => member.latitude != null && member.longitude != null,
  ),
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
  <BreadCrumbs :crumbs="crumbs" />
  <Heading>
    {{ t("headlines.fleets.members.worldmap") }}
    <small v-if="membersWithLocation.length" class="text-muted">
      {{ membersWithLocation.length }} / {{ memberItems.length }}
    </small>
  </Heading>


  <Loader :loading="asyncStatus.isLoading.value" />

  <MembersWorldMap v-if="!asyncStatus.isLoading.value" :members="memberItems" />
</template>
