<script lang="ts">
export default {
  name: "FleetMissionEditPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import MissionForm from "@/frontend/components/Fleets/Missions/MissionForm/index.vue";
import {
  type Fleet,
  type FleetMember,
  useFleetMission,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const missionSlug = computed(() => route.params.mission as string);

const {
  data: mission,
  isLoading,
  refetch,
} = useFleetMission(fleetSlug, missionSlug);

const comlink = useComlink();

onMounted(() => {
  comlink.on("fleet-mission-updated", () => void refetch());
  comlink.on("mission-children-changed", () => void refetch());
});

const cancel = () => {
  if (mission.value) {
    void router.push({
      name: "fleet-mission",
      params: { slug: props.fleet.slug, mission: mission.value.slug },
    });
    return;
  }

  void router.push({
    name: "fleet-missions",
    params: { slug: props.fleet.slug },
  });
};

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
            params: {
              slug: props.fleet.slug,
              mission: mission.value.slug,
            },
          },
          label: mission.value.title,
        },
      ]
    : []),
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Loader :loading="isLoading" />

  <div v-if="mission">
    <Heading size="hero" hero>
      {{ t("headlines.fleets.missions.edit") }}
    </Heading>

    <MissionForm :fleet="fleet" :mission="mission" @cancel="cancel" />
  </div>
</template>
