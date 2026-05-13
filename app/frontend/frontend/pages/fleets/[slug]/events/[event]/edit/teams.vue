<script lang="ts">
export default {
  name: "FleetEventEditTeamsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import EventTeamCard from "@/frontend/components/Fleets/Events/EventTeamCard/index.vue";
import {
  type Fleet,
  type FleetEventExtended,
  type FleetEventTeam,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const teams = computed<FleetEventTeam[]>(
  () => (props.event.teams ?? []) as FleetEventTeam[],
);

const openAddTeamModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventTeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
    },
  });
};
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.events.editTeams") }}</Heading>

  <div class="event-edit-teams__header">
    <Btn :size="BtnSizesEnum.SMALL" inline @click="openAddTeamModal">
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.fleets.events.addTeam") }}</span>
    </Btn>
  </div>

  <div class="event-edit-teams__list">
    <EventTeamCard
      v-for="team in teams"
      :key="team.id"
      :team="team"
      :event="event"
      :fleet="fleet"
      editable
      is-manager
    />
  </div>

  <p v-if="!teams.length" class="text-muted">
    {{ t("labels.fleets.missions.noTeams") }}
  </p>
</template>

<style lang="scss" scoped>
.event-edit-teams__header {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 0.75rem;
}
.event-edit-teams__list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
