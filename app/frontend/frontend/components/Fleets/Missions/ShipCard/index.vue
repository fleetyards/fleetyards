<script lang="ts">
export default {
  name: "FleetMissionsShipCard",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  PanelShadowsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import SlotList from "@/frontend/components/Fleets/Missions/SlotList/index.vue";
import {
  type Fleet,
  type Mission,
  type MissionShip,
  type MissionTeam,
  useDestroyMissionShip,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  mission: Mission;
  team: MissionTeam;
  ship: MissionShip;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const openEditShipModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/ShipModal/index.vue"),
    props: {
      fleet: props.fleet,
      mission: props.mission,
      team: props.team,
      ship: props.ship,
    },
  });
};

const destroyMutation = useDestroyMissionShip();

const removeShip = async () => {
  await destroyMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      missionSlug: props.mission.slug,
      missionTeamId: props.team.id,
      id: props.ship.id,
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleets.missionShip.destroy.success"),
      });
      comlink.emit("mission-children-changed");
    })
    .catch(() => {
      displayAlert({ text: t("messages.fleets.missionShip.destroy.failure") });
    });
};

const shipImage = computed<string | undefined>(() => {
  const img = props.ship.model?.image as
    | { mediumUrl?: string; smallUrl?: string }
    | undefined;
  return img?.mediumUrl || img?.smallUrl;
});

const hasShipImage = computed(() => !!shipImage.value);

const filterSummary = computed(() => {
  const f = props.ship.filters;
  if (!f) return null;
  const parts: string[] = [];
  if (f.classification) parts.push(f.classification);
  if (f.focus) parts.push(f.focus);
  if (f.minSize)
    parts.push(`${t("labels.fleets.missions.minSize")}: ${f.minSize}`);
  if (f.maxSize)
    parts.push(`${t("labels.fleets.missions.maxSize")}: ${f.maxSize}`);
  if (f.minCrew != null)
    parts.push(`${t("labels.fleets.missions.minCrew")}: ${f.minCrew}`);
  if (f.minCargo != null) parts.push(`${f.minCargo} SCU`);
  return parts.length ? parts.join(" · ") : null;
});

const headerTitle = computed(
  () => props.ship.displayTitle ?? props.ship.title ?? "—",
);

const subtitle = computed(() => {
  if (props.ship.model?.name && headerTitle.value !== props.ship.model.name) {
    return props.ship.model.name;
  }
  return filterSummary.value;
});
</script>

<template>
  <Panel
    class="mission-ship-panel"
    :class="{ 'mission-ship-panel--placeholder': !hasShipImage }"
    :bg-image="hasShipImage ? shipImage : undefined"
    :bg-rounded="PanelBgRoundedEnum.TOP"
    :shadow="PanelShadowsEnum.TOP"
  >
    <template #default>
      <div v-if="!hasShipImage" class="ship-placeholder" aria-hidden="true">
        <i class="fa-duotone fa-starship ship-placeholder-ship" />
        <i class="fa-solid fa-question ship-placeholder-question" />
      </div>
      <PanelHeading :level="HeadingLevelEnum.H4">
        <template #default>
          <span class="ship-title-row">
            <span v-if="editable" class="ship-drag-handle" title="Drag">
              ⋮⋮
            </span>
            {{ headerTitle }}
          </span>
        </template>
        <template v-if="subtitle" #subtitle>
          <span class="ship-subtitle">{{ subtitle }}</span>
        </template>
        <template v-if="editable" #actions>
          <BtnDropdown
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.LINK"
            class="ship-context-menu"
            expand-left
            expand-bottom
            inline
          >
            <Btn
              :size="BtnSizesEnum.SMALL"
              :inline="true"
              @click="openEditShipModal"
            >
              <i class="fa fa-pencil" />
              <span>{{ t("actions.edit") }}</span>
            </Btn>
            <Btn
              :size="BtnSizesEnum.SMALL"
              :inline="true"
              variant="danger"
              @click="removeShip"
            >
              <i class="fa-light fa-trash" />
              <span>{{ t("actions.delete") }}</span>
            </Btn>
          </BtnDropdown>
        </template>
      </PanelHeading>
      <PanelBody v-if="ship.description" class="mission-ship-body">
        <p class="ship-desc">
          {{ ship.description }}
        </p>
      </PanelBody>
    </template>

    <template #footer>
      <div class="mission-ship-slots">
        <h5 class="mission-ship-slots-label">
          {{ t("headlines.fleets.missions.slots") }}
        </h5>
        <SlotList
          slottable-type="MissionShip"
          :slottable-id="ship.id"
          :slots="ship.slots"
          :editable="editable"
        />
      </div>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
.mission-ship-panel {
  width: 380px;
  min-width: 350px;
  flex-shrink: 0;
}
.mission-ship-panel :deep(.panel-bg) {
  height: 160px;
  bottom: auto;
}
.mission-ship-panel :deep(.panel-inner) {
  min-height: 160px;
}
.ship-placeholder {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(
    180deg,
    rgba(60, 70, 90, 0.4) 0%,
    rgba(20, 25, 35, 0.7) 100%
  );
  border-top-left-radius: $panelInnerBorderRadius;
  border-top-right-radius: $panelInnerBorderRadius;
  pointer-events: none;
  z-index: 0;
}
.ship-placeholder-ship {
  font-size: 4.5rem;
  color: rgba(255, 255, 255, 0.18);
}
.ship-placeholder-question {
  position: absolute;
  font-size: 1.6rem;
  color: rgba(255, 255, 255, 0.55);
  background: rgba(0, 0, 0, 0.55);
  border-radius: 50%;
  width: 2.4rem;
  height: 2.4rem;
  display: flex;
  align-items: center;
  justify-content: center;
}
.ship-title-row {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}
.ship-drag-handle {
  cursor: grab;
  color: var(--text-muted);
  font-size: 0.8rem;
  letter-spacing: -0.15em;
  user-select: none;
}
.ship-subtitle {
  font-size: 0.8rem;
  color: var(--text-muted);
}
.ship-desc {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin: 0;
}
.mission-ship-slots {
  padding: 0.75rem 0.85rem;
  background: rgba(0, 0, 0, 0.55);
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  border-bottom-left-radius: $panelInnerBorderRadius;
  border-bottom-right-radius: $panelInnerBorderRadius;
}
.mission-ship-slots-label {
  margin: 0 0 0.4rem;
  font-size: 0.65rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}
</style>
