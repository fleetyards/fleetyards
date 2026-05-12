<script lang="ts">
export default {
  name: "FleetMissionEditTeamsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import TeamCard from "@/frontend/components/Fleets/Missions/TeamCard/index.vue";
import {
  type Fleet,
  type MissionExtended,
  type MissionTeam,
  useSortMissionTeams,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import Sortable from "sortablejs";

type Props = {
  fleet: Fleet;
  mission: MissionExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();

const teams = ref<MissionTeam[]>([]);

watch(
  () => props.mission,
  (newMission) => {
    teams.value = [...newMission.teams];
  },
  { immediate: true },
);

const sortTeamsMutation = useSortMissionTeams();

const teamsContainer = ref<HTMLElement | null>(null);
let teamsSortable: Sortable | null = null;

const initTeamsSortable = () => {
  teamsSortable?.destroy();
  if (!teamsContainer.value) return;

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
        .map((id) => teams.value.find((team) => team.id === id))
        .filter(Boolean) as MissionTeam[];

      void sortTeamsMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          missionSlug: props.mission.slug,
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

watch(teams, () => {
  void nextTick(() => initTeamsSortable());
});

onMounted(() => {
  void nextTick(() => initTeamsSortable());
});

onUnmounted(() => {
  teamsSortable?.destroy();
});

const openAddTeamModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/TeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      mission: props.mission,
    },
  });
};
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.missions.editTeams") }}</Heading>

  <div class="mission-edit-teams__header">
    <Btn :size="BtnSizesEnum.SMALL" inline @click="openAddTeamModal">
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.fleets.missions.addTeam") }}</span>
    </Btn>
  </div>

  <div ref="teamsContainer" class="mission-edit-teams__list">
    <TeamCard
      v-for="team in teams"
      :key="team.id"
      :data-team-id="team.id"
      :team="team"
      :fleet="fleet"
      :mission="mission"
      editable
    />
  </div>

  <p v-if="!teams.length" class="text-muted">
    {{ t("labels.fleets.missions.noTeams") }}
  </p>
</template>

<style lang="scss" scoped>
.mission-edit-teams__header {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 0.75rem;
}
.mission-edit-teams__list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
