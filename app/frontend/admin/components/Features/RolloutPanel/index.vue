<script lang="ts">
export default {
  name: "FeatureRolloutPanel",
};
</script>

<script lang="ts" setup>
import { type Feature } from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import GateRow from "@/admin/components/Features/GateRow/index.vue";
import PercentageGate from "@/admin/components/Features/PercentageGate/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatureActions } from "@/admin/composables/useFeatureActions";

interface Props {
  feature: Feature;
}

const props = defineProps<Props>();

const { t } = useI18n();

const actions = useFeatureActions(() => props.feature.name);

const KNOWN_GROUPS = ["testers", "admins"];

// A group enabled from the console that the admin does not offer still shows,
// so it can be switched off here.
const groups = computed(() => [
  ...KNOWN_GROUPS,
  ...props.feature.groups.filter((group) => !KNOWN_GROUPS.includes(group)),
]);

const isEnabled = (group: string) => props.feature.groups.includes(group);

const toggleGroup = (group: string) =>
  isEnabled(group) ? actions.removeGroup(group) : actions.addGroup(group);
</script>

<template>
  <Panel :outer-spacing="false">
    <PanelHeading>{{ t("headlines.admin.features.rollout") }}</PanelHeading>
    <PanelBody>
      <GateRow
        :label="t('labels.features.gates.groups.label')"
        :hint="t('labels.features.gates.groups.hint')"
        data-test="feature-groups"
      >
        <div class="feature-rollout__groups">
          <Chip
            v-for="group in groups"
            :key="group"
            :state="
              isEnabled(group)
                ? ChipStatesEnum.INCLUDED
                : ChipStatesEnum.NEUTRAL
            "
            :disabled="actions.busy.value"
            :data-test="`feature-group-${group}`"
            @toggle="toggleGroup(group)"
          >
            {{ group }}
          </Chip>
        </div>
      </GateRow>

      <GateRow
        :label="t('labels.features.gates.percentageOfActors.label')"
        :hint="t('labels.features.gates.percentageOfActors.hint')"
      >
        <PercentageGate
          name="actors"
          :label="t('labels.features.gates.percentageOfActors.label')"
          :value="feature.percentageOfActors"
          :loading="actions.busy.value"
          @apply="actions.setPercentageOfActors"
        />
      </GateRow>

      <GateRow
        :label="t('labels.features.gates.percentageOfTime.label')"
        :hint="t('labels.features.gates.percentageOfTime.hint')"
      >
        <PercentageGate
          name="time"
          :label="t('labels.features.gates.percentageOfTime.label')"
          :value="feature.percentageOfTime"
          :loading="actions.busy.value"
          @apply="actions.setPercentageOfTime"
        />
      </GateRow>

      <GateRow
        :label="t('labels.features.gates.optIn.label')"
        :hint="t('labels.features.gates.optIn.hint')"
        data-test="feature-self-service"
      >
        <div class="feature-rollout__toggles">
          <Toggle
            :active="feature.selfServiceUser"
            :loading="actions.busy.value"
            :label="t('labels.features.selfServiceUser')"
            :info="t('labels.features.gates.optIn.userInfo')"
            data-test="toggle-self-service"
            @toggle="actions.toggleUserSelfService()"
          />
          <Toggle
            :active="feature.selfServiceFleet"
            :loading="actions.busy.value"
            :label="t('labels.features.selfServiceFleet')"
            :info="t('labels.features.gates.optIn.fleetInfo')"
            data-test="toggle-fleet-self-service"
            @toggle="actions.toggleFleetSelfService()"
          />
        </div>
      </GateRow>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.feature-rollout__groups {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}

.feature-rollout__toggles {
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
}
</style>
