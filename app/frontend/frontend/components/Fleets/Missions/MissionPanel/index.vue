<script lang="ts">
export default {
  name: "FleetMissionsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import {
  PanelShadowsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { type Fleet, type Mission } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionCover } from "@/frontend/composables/useMissionCover";

type Props = {
  fleet: Fleet;
  mission: Mission;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
});

const { t } = useI18n();
const { resolve } = useMissionCover();
const cover = computed(() => resolve(props.mission));
</script>

<template>
  <Panel
    :shadow="PanelShadowsEnum.TOP"
    :bg-image="cover"
    :bg-rounded="PanelBgRoundedEnum.TOP"
    class="mission-panel"
  >
    <PanelHeading :level="HeadingLevelEnum.H2">
      <template #default>
        <router-link
          :to="{
            name: 'fleet-mission',
            params: { slug: fleet.slug, mission: mission.slug },
          }"
        >
          {{ mission.title }}
        </router-link>
      </template>
      <template v-if="mission.archived" #subtitle>
        <span class="text-muted">
          {{ t("labels.fleets.missions.archived") }}
        </span>
      </template>
    </PanelHeading>
    <PanelBody>
      <p v-if="mission.description" class="mission-desc text-muted">
        {{ mission.description }}
      </p>
      <ul class="mission-stats">
        <li>
          <strong>{{ mission.teamCount }}</strong>
          {{ t("labels.fleets.missions.teams") }}
        </li>
        <li>
          <strong>{{ mission.shipCount }}</strong>
          {{ t("labels.fleets.missions.ships") }}
        </li>
      </ul>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
$missionImageHeight: 200px;

.mission-panel :deep(.panel-bg) {
  height: $missionImageHeight;
  bottom: auto;
}
.mission-panel :deep(.panel-inner) {
  padding-top: $missionImageHeight;
  position: relative;
}
.mission-panel :deep(.panel-heading) {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: auto;
  z-index: 1;
}
.mission-panel :deep(.panel-body) {
  position: relative;
}
.mission-desc {
  margin: 0 0 0.5rem;
  font-size: 0.9rem;
}
.mission-stats {
  display: flex;
  gap: 1rem;
  list-style: none;
  padding: 0;
  margin: 0;
  font-size: 0.85rem;
  color: var(--text-muted);

  strong {
    color: var(--text);
  }
}
</style>
