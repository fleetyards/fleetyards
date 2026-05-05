<script lang="ts">
export default {
  name: "FleetMissionPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import TeamCard from "@/frontend/components/Fleets/Missions/TeamCard/index.vue";
import {
  type Fleet,
  type FleetEvent,
  type FleetMember,
  type MissionExtended,
  type MissionTeam,
  useFleetMission,
  useDestroyFleetMission,
  useUpdateFleetMission,
  useSortMissionTeams,
  useFleetEvents,
} from "@/services/fyApi";
import EventPanel from "@/frontend/components/Fleets/Events/EventPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import Sortable from "sortablejs";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const missionSlug = computed(() => route.params.mission as string);

const {
  data: mission,
  isLoading,
  refetch,
} = useFleetMission(fleetSlug, missionSlug);

const teams = ref<MissionTeam[]>([]);

watch(
  mission,
  (newMission: MissionExtended | undefined) => {
    if (!newMission) return;
    teams.value = [...newMission.teams];
  },
  { immediate: true },
);

const canEdit = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:update",
  ]),
);

const canDelete = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:delete",
  ]),
);

const archiveMutation = useDestroyFleetMission();
const updateMutation = useUpdateFleetMission();
const sortTeamsMutation = useSortMissionTeams();

const openEditModal = () => {
  if (!mission.value) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/MissionModal/index.vue"),
    props: {
      fleet: props.fleet,
      mission: mission.value,
    },
  });
};

const canCreateEvents = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:create",
  ]),
);

const goToSpawnEvent = () => {
  if (!mission.value) return;
  void router.push({
    name: "fleet-event-new",
    params: { slug: props.fleet.slug },
    query: { mission: mission.value.slug },
  });
};

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
});

const openAddTeamModal = () => {
  if (!mission.value) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/TeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      mission: mission.value,
    },
  });
};

const archiveMission = async () => {
  if (!mission.value) return;
  await archiveMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: mission.value.slug,
    })
    .then(async () => {
      displaySuccess({ text: t("messages.fleets.mission.archive.success") });
      await router.push({
        name: "fleet-missions",
        params: { slug: props.fleet.slug },
      });
    })
    .catch(() => {
      displayAlert({ text: t("messages.fleets.mission.archive.failure") });
    });
};

const unarchiveMission = async () => {
  if (!mission.value) return;
  await updateMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: mission.value.slug,
      data: { archivedAt: null },
    })
    .then(() => {
      displaySuccess({ text: t("messages.fleets.mission.unarchive.success") });
    })
    .catch(() => {
      displayAlert({ text: t("messages.fleets.mission.unarchive.failure") });
    });
};

const destroyMission = () => {
  if (!mission.value) return;
  displayConfirm({
    text: t("messages.fleets.mission.destroy.confirm"),
    confirmText: t("actions.fleets.missions.destroy"),
    onConfirm: async () => {
      if (!mission.value) return;
      await archiveMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          slug: mission.value.slug,
        })
        .then(async () => {
          displaySuccess({
            text: t("messages.fleets.mission.destroy.success"),
          });
          await router.push({
            name: "fleet-missions",
            params: { slug: props.fleet.slug },
          });
        })
        .catch(() => {
          displayAlert({ text: t("messages.fleets.mission.destroy.failure") });
        });
    },
  });
};

const teamsContainer = ref<HTMLElement | null>(null);
let teamsSortable: Sortable | null = null;

const initTeamsSortable = () => {
  teamsSortable?.destroy();
  if (!teamsContainer.value || !canEdit.value) return;

  teamsSortable = Sortable.create(teamsContainer.value, {
    animation: 150,
    handle: ".team-drag-handle",
    onEnd: () => {
      const items = teamsContainer.value?.querySelectorAll("[data-team-id]");
      if (!items) return;
      const order = Array.from(items)
        .map((el) => el.getAttribute("data-team-id"))
        .filter(Boolean) as string[];

      teams.value = order
        .map((id) => teams.value.find((t) => t.id === id))
        .filter(Boolean) as MissionTeam[];

      void sortTeamsMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          missionSlug: mission.value!.slug,
          data: { sorting: order },
        })
        .catch(() =>
          displayAlert({
            text: t("messages.fleets.missionTeam.update.failure"),
          }),
        );
    },
  });
};

watch([teams, canEdit], () => {
  void nextTick(() => initTeamsSortable());
});

onMounted(() => {
  comlink.on("fleet-mission-updated", () => void refetch());
  comlink.on("mission-children-changed", () => void refetch());
});

onUnmounted(() => {
  teamsSortable?.destroy();
});

const crumbs = computed(() => [
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
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Loader :loading="isLoading" />

  <div v-if="mission">
    <div
      class="mission-cover"
      :style="{ backgroundImage: `url(${coverImage})` }"
    />
    <Heading size="hero" hero>{{ mission.title }}</Heading>
    <p v-if="mission.description" class="text-muted">
      {{ mission.description }}
    </p>

    <Teleport v-if="canEdit" to="#header-right">
      <Btn
        v-if="canCreateEvents && !mission.archived"
        size="small"
        inline
        @click="goToSpawnEvent"
      >
        <i class="fa-light fa-calendar-plus" />
        <span>{{ t("actions.fleets.events.spawn") }}</span>
      </Btn>
      <Btn size="small" @click="openEditModal">
        <i class="fa-light fa-pen" />
        <span>{{ t("actions.fleets.missions.edit") }}</span>
      </Btn>
      <Btn v-if="mission.archived" size="small" @click="unarchiveMission">
        <i class="fa-light fa-box-open" />
        <span>{{ t("actions.fleets.missions.unarchive") }}</span>
      </Btn>
      <Btn
        v-if="canDelete && !mission.archived"
        size="small"
        variant="danger"
        @click="archiveMission"
      >
        <i class="fa-light fa-archive" />
        <span>{{ t("actions.fleets.missions.archive") }}</span>
      </Btn>
      <Btn
        v-if="canDelete && mission.archived"
        size="small"
        variant="danger"
        @click="destroyMission"
      >
        <i class="fa-light fa-trash" />
        <span>{{ t("actions.fleets.missions.destroy") }}</span>
      </Btn>
    </Teleport>

    <section class="mission-section">
      <div class="section-header">
        <Heading>{{ t("headlines.fleets.missions.teams") }}</Heading>
        <Btn
          v-if="canEdit"
          :inline="true"
          size="small"
          @click="openAddTeamModal"
        >
          <i class="fa-light fa-plus" />
          <span>{{ t("actions.fleets.missions.addTeam") }}</span>
        </Btn>
      </div>
      <div ref="teamsContainer" class="mission-teams">
        <TeamCard
          v-for="team in teams"
          :key="team.id"
          :data-team-id="team.id"
          :team="team"
          :fleet="fleet"
          :mission="mission"
          :editable="canEdit"
        />
      </div>
      <p v-if="!teams.length" class="text-muted">
        {{ t("labels.fleets.missions.noTeams") }}
      </p>
    </section>

    <section v-if="spawnedEventList.length" class="mission-section">
      <div class="section-header">
        <Heading>{{ t("headlines.fleets.events.spawnedFrom") }}</Heading>
      </div>
      <div class="spawned-events">
        <EventPanel
          v-for="event in spawnedEventList"
          :key="event.id"
          :event="event"
          :fleet="fleet"
        />
      </div>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.mission-cover {
  width: 100%;
  height: 220px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  border-radius: 6px;
  margin-bottom: 1.25rem;
}
.mission-section {
  margin-top: 2rem;
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
}
.mission-teams {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
