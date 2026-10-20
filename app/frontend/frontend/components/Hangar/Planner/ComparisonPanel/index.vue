<script lang="ts">
export default {
  name: "HangarPlannerComparisonPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import MetricsTable from "@/frontend/components/Hangar/Planner/MetricsTable/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarPlanComparison,
  HangarPlanModelChangeEnum,
  HangarPlanVehicleStatusEnum,
} from "@/services/fyApi";

type Props = {
  comparison?: HangarPlanComparison;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  comparison: undefined,
  loading: false,
});

const { t } = useI18n();

const statusVariant = (status: HangarPlanVehicleStatusEnum) => {
  switch (status) {
    case HangarPlanVehicleStatusEnum.KEPT:
      return PillVariantsEnum.SUCCESS;
    case HangarPlanVehicleStatusEnum.UPGRADED:
      return PillVariantsEnum.DEFAULT;
    case HangarPlanVehicleStatusEnum.MELTED:
      return PillVariantsEnum.DANGER;
    default:
      return PillVariantsEnum.NEUTRAL;
  }
};

const changedModels = computed(() =>
  (props.comparison?.models ?? []).filter(
    (diff) => diff.change !== HangarPlanModelChangeEnum.UNCHANGED,
  ),
);
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    :loading="loading"
    data-test="hangar-plan-comparison"
  >
    <PanelHeading compact divider>
      {{ t("hangarPlanner.comparison.title") }}
    </PanelHeading>
    <PanelBody v-if="comparison">
      <div class="plan-comparison">
        <section>
          <h4>{{ t("hangarPlanner.comparison.yourShips") }}</h4>
          <p v-if="!comparison.vehicles.length" class="plan-comparison__muted">
            {{ t("hangarPlanner.comparison.noShips") }}
          </p>
          <ul>
            <li
              v-for="entry in comparison.vehicles"
              :key="entry.vehicleId"
              data-test="hangar-plan-vehicle-status"
            >
              <Pill :variant="statusVariant(entry.status)">
                {{ t(`hangarPlanner.vehicleStatuses.${entry.status}`) }}
              </Pill>
              {{ entry.name || entry.model.name }}
              <span
                v-if="entry.status === HangarPlanVehicleStatusEnum.UPGRADED"
                class="plan-comparison__muted"
              >
                → {{ entry.targetModel?.name }}
              </span>
            </li>
          </ul>
        </section>

        <section>
          <h4>{{ t("hangarPlanner.comparison.changes") }}</h4>
          <p v-if="!changedModels.length" class="plan-comparison__muted">
            {{ t("hangarPlanner.comparison.noChanges") }}
          </p>
          <ul>
            <li
              v-for="diff in changedModels"
              :key="diff.model.id"
              data-test="hangar-plan-model-diff"
            >
              <Pill :variant="PillVariantsEnum.NEUTRAL">
                {{ t(`hangarPlanner.changes.${diff.change}`) }}
              </Pill>
              {{ diff.model.name }}
              <span class="plan-comparison__muted">
                {{ diff.leftCount }} → {{ diff.rightCount }}
              </span>
            </li>
          </ul>

          <template v-if="comparison.gaps.length">
            <h4>{{ t("hangarPlanner.comparison.toAcquire") }}</h4>
            <ul>
              <li v-for="gap in comparison.gaps" :key="gap.slotId">
                {{ gap.count }} × {{ gap.model.name }}
                <span class="plan-comparison__muted">({{ gap.label }})</span>
              </li>
            </ul>
          </template>
        </section>
      </div>

      <MetricsTable
        :left="comparison.metrics.live"
        :right="comparison.metrics.plan"
        :left-label="t('hangarPlanner.comparison.hangar')"
        :right-label="t('hangarPlanner.comparison.plan')"
      />
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.plan-comparison {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 16px;
  margin-bottom: 16px;

  h4 {
    margin: 0 0 8px;
    font-size: 0.9rem;
    color: var(--color-text-dim);
  }

  ul {
    margin: 0 0 12px;
    padding: 0;
    list-style: none;
  }

  li {
    padding: 2px 0;
  }
}

.plan-comparison__muted {
  color: var(--color-text-dim);
}
</style>
