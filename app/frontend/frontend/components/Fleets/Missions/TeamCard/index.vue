<script lang="ts">
export default {
  name: "FleetMissionsTeamCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
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
  <Panel :variant="PanelVariantsEnum.SLIM" class="team-box">
    <!--
      D6: a titled sub-surface inside a page, so a slim panel with a divider
      under its head rather than a hand-rolled fill. The three controls were
      bare buttons with their own hover rules and an untranslated title="Drag";
      they are Btn at chip scale now, the same as the event team card's.
    -->
    <!--
      The metric head, so the team carries the gold dot every other titled
      sub-surface in the app does. It renders a span rather than a document
      heading, which is the system's existing call for this tone.
    -->
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      <template #default>
        <span class="team-title-row">
          <span
            v-if="editable"
            v-tooltip="t('actions.reorder')"
            class="team-drag-handle"
            :aria-label="t('actions.reorder')"
          >
            <i class="fa-light fa-grip-vertical" />
          </span>
          {{ team.title }}
        </span>
      </template>
      <template v-if="editable" #actions>
        <Btn
          v-tooltip="t('actions.edit')"
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.edit')"
          @click="openEditTeamModal"
        >
          <i class="fa-light fa-pen" />
        </Btn>
        <Btn
          v-tooltip="t('actions.delete')"
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          tone="danger"
          :aria-label="t('actions.delete')"
          @click="removeTeam"
        >
          <i class="fa-light fa-xmark" />
        </Btn>
      </template>
    </PanelHeading>

    <PanelBody>
      <p v-if="team.description" class="team-desc">
        {{ team.description }}
      </p>

      <div class="team-section">
        <p class="metrics-card__section-label">
          {{ t("headlines.fleets.missions.slots") }}
        </p>
        <SlotList
          slottable-type="MissionTeam"
          :slottable-id="team.id"
          :slots="team.slots"
          :editable="editable"
        />
      </div>

      <div class="team-section">
        <div class="team-section-header">
          <p class="metrics-card__section-label">
            {{ t("headlines.fleets.missions.ships") }}
          </p>
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
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.team-title-row {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.team-drag-handle {
  cursor: grab;
  color: var(--color-muted, #7a8288);
  font-size: 13px;
  letter-spacing: -0.15em;
  user-select: none;
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
