<script lang="ts">
export default {
  name: "FleetMissionPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { PanelBgOverlayDirectionEnum } from "@/shared/components/base/Panel/types";
import TeamCard from "@/frontend/components/Fleets/Missions/TeamCard/index.vue";
import MissionAdminActions from "@/frontend/components/Fleets/Missions/MissionAdminActions/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetMember,
  useFleetMission,
  useFleetEvents,
} from "@/services/fyApi";
import EventPanel from "@/frontend/components/Fleets/Events/EventPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useMissionCover } from "@/frontend/composables/useMissionCover";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const route = useRoute();

const fleetSlug = computed(() => props.fleet.slug);
const missionSlug = computed(() => route.params.mission as string);

const {
  data: mission,
  isLoading,
  refetch,
} = useFleetMission(fleetSlug, missionSlug);

const teams = computed(() => mission.value?.teams ?? []);

const canEdit = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:update",
  ]),
);

const { data: spawnedEvents, refetch: refetchSpawnedEvents } = useFleetEvents(
  fleetSlug,
  ref({}),
  {
    query: {
      enabled: computed(() => !!mission.value?.id),
    },
  },
);

const spawnedEventList = computed<FleetEvent[]>(() => {
  const all = spawnedEvents.value?.items ?? [];
  return mission.value?.id
    ? all.filter((event) => event.missionId === mission.value!.id)
    : [];
});

onMounted(() => {
  comlink.on("fleet-event-created", () => void refetchSpawnedEvents());
  comlink.on("fleet-event-updated", () => void refetchSpawnedEvents());
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
]);

const { resolve: resolveCover } = useMissionCover();
const coverImage = computed(() => resolveCover(mission.value));
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

  <Loader :loading="isLoading" />

  <div v-if="mission" class="mission-detail">
    <Panel
      :bg-image="coverImage"
      bg-overlay
      :bg-overlay-direction="PanelBgOverlayDirectionEnum.RIGHT"
    >
      <template #hero>
        <Heading size="hero" hero>{{ mission.title }}</Heading>
      </template>
      <div v-if="mission.description" class="mission-overview">
        <p class="mission-description">{{ mission.description }}</p>
      </div>
    </Panel>

    <section v-if="teams.length" class="mission-section">
      <div class="section-header">
        <Heading>{{ t("headlines.fleets.missions.teams") }}</Heading>
      </div>
      <div class="mission-teams">
        <TeamCard
          v-for="team in teams"
          :key="team.id"
          :team="team"
          :fleet="fleet"
          :mission="mission"
        />
      </div>
    </section>

    <section v-if="spawnedEventList.length" class="mission-section">
      <div class="section-header">
        <Heading>{{ t("headlines.fleets.events.spawnedFrom") }}</Heading>
      </div>
      <div class="spawned-events">
        <div
          v-for="event in spawnedEventList"
          :key="event.id"
          class="spawned-events__item"
        >
          <EventPanel :event="event" :fleet="fleet" />
        </div>
      </div>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.mission-detail {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.mission-overview {
  padding: 1rem 1.5rem 1.25rem;
}
.mission-description {
  margin: 0;
  white-space: pre-wrap;
}
.mission-section {
  margin-top: 1rem;
}
.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 0.75rem;
}
.spawned-events {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1rem;
  align-items: start;
}
.spawned-events__item {
  display: flex;
  flex-direction: column;
}
.spawned-events__item :deep(.panel-wrapper--outer-spacing) {
  margin-bottom: 0;
}
.mission-teams {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
