<script lang="ts">
export default {
  name: "FleetMissionEditLayout",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import MissionAdminActions from "@/frontend/components/Fleets/Missions/MissionAdminActions/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as editRoutes } from "@/frontend/pages/fleets/[slug]/missions/[mission]/edit/routes";
import {
  type Fleet,
  type FleetMember,
  useFleetMission,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const comlink = useComlink();

const fleetSlug = computed(() => props.fleet.slug);
const missionSlug = computed(() => route.params.mission as string);

const { data: mission, refetch } = useFleetMission(fleetSlug, missionSlug);

// The create button lands an author here with a draft, so the two things they
// may want next -- publish it, or throw it away -- have to be reachable from
// this page and not only from the one they skipped.
const canEdit = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:update",
  ]),
);

const fleetMissionUpdatedComlink = ref<() => void>();
const missionChildrenChangedComlink = ref<() => void>();

onMounted(() => {
  fleetMissionUpdatedComlink.value = comlink.on(
    "fleet-mission-updated",
    () => void refetch(),
  );
  missionChildrenChangedComlink.value = comlink.on(
    "mission-children-changed",
    () => void refetch(),
  );
});

onUnmounted(() => {
  fleetMissionUpdatedComlink.value?.();
  missionChildrenChangedComlink.value?.();
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-events", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.events.index"),
  },
  {
    to: { name: "fleet-missions", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.missions.index"),
  },
  ...(mission.value
    ? [
        {
          to: {
            name: "fleet-mission",
            params: { slug: props.fleet.slug, mission: mission.value.slug },
          },
          label: mission.value.title,
        },
      ]
    : []),
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs">
    <template v-if="canEdit && mission" #actions>
      <MissionAdminActions
        :fleet="fleet"
        :mission="mission"
        :resource-access="resourceAccess"
      />
    </template>
  </BreadCrumbs>

  <TabNavView v-if="mission">
    <template #nav>
      <TabNavViewItems
        :routes="editRoutes"
        :authenticated="true"
        :resource-access="resourceAccess"
      />
    </template>
    <template #content>
      <router-view :fleet="fleet" :mission="mission" />
    </template>
  </TabNavView>
</template>
