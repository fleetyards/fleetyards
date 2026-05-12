<script lang="ts">
export default {
  name: "FleetMissionEditLayout",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
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

onMounted(() => {
  comlink.on("fleet-mission-updated", () => void refetch());
  comlink.on("mission-children-changed", () => void refetch());
});

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
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
  <BreadCrumbs :crumbs="crumbs" />

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
