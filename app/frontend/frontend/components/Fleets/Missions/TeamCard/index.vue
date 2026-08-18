<script lang="ts">
export default {
  name: "FleetMissionsTeamCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import SlotList from "@/frontend/components/Fleets/Missions/SlotList/index.vue";
import ShipCard from "@/frontend/components/Fleets/Missions/ShipCard/index.vue";
import {
  type Fleet,
  type Mission,
  type MissionShip,
  type MissionTeam,
  useDestroyMissionTeam,
  useSortMissionShips,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import Sortable from "sortablejs";

type Props = {
  fleet: Fleet;
  mission: Mission;
  team: MissionTeam;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const ships = ref<MissionShip[]>([]);

const openEditTeamModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/TeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      mission: props.mission,
      team: props.team,
    },
  });
};

const openAddShipModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/ShipModal/index.vue"),
    props: {
      fleet: props.fleet,
      mission: props.mission,
      team: props.team,
    },
  });
};

watch(
  () => props.team.ships,
  (newShips) => {
    ships.value = [...newShips];
  },
  { immediate: true },
);

const destroyMutation = useDestroyMissionTeam();
const sortShipsMutation = useSortMissionShips();

const removeTeam = async () => {
  await destroyMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      missionSlug: props.mission.slug,
      id: props.team.id,
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleets.missionTeam.destroy.success"),
      });
      comlink.emit("mission-children-changed");
    })
    .catch(() => {
      displayAlert({ text: t("messages.fleets.missionTeam.destroy.failure") });
    });
};

const shipsContainer = ref<HTMLElement | null>(null);
let shipsSortable: Sortable | null = null;

const initShipsSortable = () => {
  shipsSortable?.destroy();
  if (!shipsContainer.value || !props.editable) return;

  shipsSortable = Sortable.create(shipsContainer.value, {
    animation: 150,
    handle: ".ship-drag-handle",
    onEnd: () => {
      const items = shipsContainer.value?.querySelectorAll("[data-ship-id]");
      if (!items) return;
      const order = Array.from(items)
        .map((el) => el.getAttribute("data-ship-id"))
        .filter(Boolean) as string[];

      ships.value = order
        .map((id) => ships.value.find((s) => s.id === id))
        .filter(Boolean) as MissionShip[];

      void sortShipsMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          missionSlug: props.mission.slug,
          missionTeamId: props.team.id,
          data: { sorting: order },
        })
        .catch(() =>
          displayAlert({
            text: t("messages.fleets.missionShip.update.failure"),
          }),
        );
    },
  });
};

watch([ships, () => props.editable], () => {
  void nextTick(() => initShipsSortable());
});

onMounted(() => {
  void nextTick(() => initShipsSortable());
});

onUnmounted(() => {
  shipsSortable?.destroy();
});
</script>

<template>
  <section class="team-box">
    <button
      v-if="editable"
      type="button"
      class="team-close"
      :title="t('actions.delete')"
      @click="removeTeam"
    >
      <i class="fa-light fa-xmark" />
    </button>

    <div class="team-header">
      <span
        v-if="editable"
        v-tooltip="t('actions.reorder')"
        class="team-drag-handle"
        :aria-label="t('actions.reorder')"
      >
        <i class="fa-light fa-grip-vertical" />
      </span>
      <h3 class="team-title">{{ team.title }}</h3>
      <button
        v-if="editable"
        type="button"
        class="team-edit"
        :title="t('actions.edit')"
        @click="openEditTeamModal"
      >
        <i class="fa-light fa-pen" />
      </button>
    </div>

    <p v-if="team.description" class="team-desc">
      {{ team.description }}
    </p>

    <div class="team-section">
      <h4 class="team-section-label">
        {{ t("headlines.fleets.missions.slots") }}
      </h4>
      <SlotList
        slottable-type="MissionTeam"
        :slottable-id="team.id"
        :slots="team.slots"
        :editable="editable"
      />
    </div>

    <div class="team-section">
      <div class="team-section-header">
        <h4 class="team-section-label">
          {{ t("headlines.fleets.missions.ships") }}
        </h4>
        <Btn v-if="editable" @click="openAddShipModal">
          <i class="fa-light fa-plus" />
          <span>{{ t("actions.fleets.missions.addShip") }}</span>
        </Btn>
      </div>
      <div ref="shipsContainer" class="team-ships">
        <ShipCard
          v-for="ship in ships"
          :key="ship.id"
          :data-ship-id="ship.id"
          :ship="ship"
          :fleet="fleet"
          :mission="mission"
          :team="team"
          :editable="editable"
        />
      </div>
      <p v-if="!ships.length" class="text-muted no-ships">
        {{ t("labels.fleets.missions.noShips") }}
      </p>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.team-box {
  position: relative;
  padding: 20px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control-bare, 6px);
  background: rgba(0, 0, 0, 0.45);
  margin-bottom: 24px;
}
.team-close {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  background: transparent;
  border: none;
  color: var(--color-muted, #7a8288);
  cursor: pointer;
  padding: 4px 8px;
  font-size: 16px;
  line-height: 1;
  border-radius: var(--radius-control-bare, 6px);
  transition:
    color 0.15s,
    background 0.15s;

  &:hover {
    color: var(--color-danger, #dc3545);
    background: rgba(255, 255, 255, 0.06);
  }
}
.team-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding-right: 40px;
}
.team-drag-handle {
  cursor: grab;
  color: var(--color-muted, #7a8288);
  font-size: 13px;
  letter-spacing: -0.15em;
  user-select: none;
}
.team-title {
  margin: 0;
  font-size: 19px;
  font-weight: 600;
}
.team-edit {
  background: transparent;
  border: none;
  color: var(--color-muted, #7a8288);
  cursor: pointer;
  padding: 4px 6px;
  border-radius: var(--radius-control-bare, 6px);
  font-size: 13px;
  transition:
    color 0.15s,
    background 0.15s;

  &:hover {
    color: var(--color-text, #c8c8c8);
    background: rgba(255, 255, 255, 0.06);
  }
}
.team-desc {
  color: var(--color-muted, #7a8288);
  margin: 8px 0 0;
}
.team-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
}
.team-section-label {
  margin: 0;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--color-muted, #7a8288);
}
.team-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}
.team-ships {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  gap: 12px;
  align-items: flex-start;
}
.no-ships {
  font-style: italic;
  font-size: 14px;
  margin: 0;
}
</style>
