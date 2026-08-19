<script lang="ts">
export default {
  name: "FleetMissionsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingShadowEnum } from "@/shared/components/base/Panel/Heading/types";
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
    :bg-image="cover"
    :bg-rounded="PanelRoundedEnum.TOP"
    class="mission-panel"
  >
    <PanelHeading
      :level="HeadingLevelEnum.H2"
      :shadow="PanelHeadingShadowEnum.TOP"
    >
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
    </PanelHeading>

    <!-- Same treatment the event card gets: a pill in the cover's corner rather
         than a frameless chip beside the title. Neutral, because an archived
         mission asks nothing of the reader. -->
    <div v-if="mission.archived" class="mission-panel__status">
      <Pill :variant="PillVariantsEnum.NEUTRAL">
        {{ t("labels.fleets.missions.archived") }}
      </Pill>
    </div>

    <template #footer>
      <PanelBody>
        <p v-if="mission.description" class="mission-panel__lede">
          {{ mission.description }}
        </p>
        <!-- Two peer figures, which is what the hero rail is for. -->
        <div class="metrics-card__hero">
          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">
              {{ t("labels.fleets.missions.teams") }}
            </div>
            <div class="metrics-card__tile__value">
              {{ mission.teamCount }}
            </div>
          </div>
          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">
              {{ t("labels.fleets.missions.ships") }}
            </div>
            <div class="metrics-card__tile__value">
              {{ mission.shipCount }}
            </div>
          </div>
        </div>
      </PanelBody>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
/* Anchored to .panel__inner, which is the cover. */
.mission-panel__status {
  position: absolute;
  right: 14px;
  bottom: 14px;
  z-index: 2;
}

@import "@/shared/components/metricsCard";

/*
 * Replaces four :deep() rules into Panel's internals, two of which had already
 * stopped matching: the redesign collapsed .panel-inner into .panel__inner, so
 * the card lost the padding that kept its body clear of the cover.
 */
.mission-panel {
  --panel-image-height: 200px;
}

.mission-panel__lede {
  margin: 0 0 14px;
  font-size: 14px;
  color: var(--color-muted, #7a8288);
}
</style>
