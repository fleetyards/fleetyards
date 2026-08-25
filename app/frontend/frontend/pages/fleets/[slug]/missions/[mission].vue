<script lang="ts">
export default {
  name: "FleetMissionPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";
import Loader from "@/shared/components/Loader/index.vue";
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

const fleetEventCreatedComlink = ref<() => void>();
const fleetEventUpdatedComlink = ref<() => void>();
const fleetMissionUpdatedComlink = ref<() => void>();
const missionChildrenChangedComlink = ref<() => void>();

onMounted(() => {
  fleetEventCreatedComlink.value = comlink.on(
    "fleet-event-created",
    () => void refetchSpawnedEvents(),
  );
  fleetEventUpdatedComlink.value = comlink.on(
    "fleet-event-updated",
    () => void refetchSpawnedEvents(),
  );
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
  fleetEventCreatedComlink.value?.();
  fleetEventUpdatedComlink.value?.();
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
]);

const { resolve: resolveCover } = useMissionCover();
const coverImage = computed(() => resolveCover(mission.value));

// The cover reaches the panel's own edge when nothing sits under it, so its
// rounding follows the footer rather than being fixed — the pair
// Modules/Panel already uses.
const hasFooter = computed(() => !!mission.value?.description);
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
    <!--
      The rounding follows the body: a description puts content under the cover,
      so the cover's bottom corners have to stay square where the two meet, and
      without one the cover reaches the panel's own edge and has to round with
      it. Same condition as the footer below.
    -->
    <Panel
      :bg-image="coverImage"
      :bg-rounded="hasFooter ? PanelRoundedEnum.TOP : PanelRoundedEnum.ALL"
      class="mission-detail__hero"
    >
      <PanelHeading :shadow="PanelHeadingShadowEnum.TOP">
        {{ mission.title }}
      </PanelHeading>
      <template v-if="hasFooter" #footer>
        <PanelBody>
          <p class="mission-description">{{ mission.description }}</p>
        </PanelBody>
      </template>
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
  gap: 16px;
}
.mission-detail__hero {
  --panel-image-height: 260px;
}
.mission-description {
  margin: 0;
  white-space: pre-wrap;
}
.mission-section {
  margin-top: 16px;
}
.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 12px;
}
.spawned-events {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
  align-items: start;
}
.spawned-events__item {
  display: flex;
  flex-direction: column;
}
/*
 * The grid owns the gap, so the panel's own 21px would double it. Targets
 * .panel--outer-spacing: .panel-wrapper is gone, collapsed into the single box
 * the redesign left, so this selector had stopped matching anything.
 */
.spawned-events__item :deep(.panel--outer-spacing) {
  margin-bottom: 0;
}
.mission-teams {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
