<script lang="ts">
export default {
  name: "HangarPlanComparePage",
};
</script>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import MetricsTable from "@/frontend/components/Hangar/Planner/MetricsTable/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarPlanTotals,
  HangarPlanModelChangeEnum,
  useCompareHangarPlans,
  useHangarPlan,
} from "@/services/fyApi";

const route = useRoute();
const { t } = useI18n();
const { range } = usePlanMoney();

const planId = computed(() => String(route.params.id));
const otherId = computed(() => String(route.params.otherId));

const { data: plan } = useHangarPlan(planId);
const { data: compare, isLoading } = useCompareHangarPlans(planId, otherId);

const totalRows: {
  key: string;
  min: keyof HangarPlanTotals;
  max: keyof HangarPlanTotals;
}[] = [
  { key: "spend", min: "spendMin", max: "spendMax" },
  { key: "meltCredit", min: "meltCredit", max: "meltCredit" },
  { key: "net", min: "netMin", max: "netMax" },
  { key: "cashNeeded", min: "cashNeededMin", max: "cashNeededMax" },
];

const value = (totals: HangarPlanTotals, row: (typeof totalRows)[number]) =>
  range(totals[row.min] as number, totals[row.max] as number);

const changed = computed(() =>
  (compare.value?.models ?? []).filter(
    (diff) => diff.change !== HangarPlanModelChangeEnum.UNCHANGED,
  ),
);
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      { to: { name: 'hangar' }, label: t('nav.hangar.index') },
      { to: { name: 'hangar-plans' }, label: t('nav.hangar.plans') },
      {
        to: { name: 'hangar-plan', params: { id: planId } },
        label: plan?.name ?? '',
      },
    ]"
  />
  <Heading size="hero" hero>
    {{
      t("hangarPlanner.compareTitle", {
        left: plan?.name ?? "",
        right: compare?.otherPlanName ?? "",
      })
    }}
  </Heading>

  <Loader :loading="isLoading" />

  <div v-if="compare && plan" class="plan-compare">
    <Panel :variant="PanelVariantsEnum.SLIM">
      <PanelHeading compact divider>
        {{ t("hangarPlanner.summary.title") }}
      </PanelHeading>
      <PanelBody>
        <table class="plan-compare__totals">
          <thead>
            <tr>
              <th />
              <th>{{ plan.name }}</th>
              <th>{{ compare.otherPlanName }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in totalRows" :key="row.key">
              <th>{{ t(`hangarPlanner.summary.${row.key}`) }}</th>
              <td>{{ value(compare.totals.left, row) }}</td>
              <td>{{ value(compare.totals.right, row) }}</td>
            </tr>
          </tbody>
        </table>
      </PanelBody>
    </Panel>

    <Panel :variant="PanelVariantsEnum.SLIM">
      <PanelHeading compact divider>
        {{ t("hangarPlanner.comparison.changes") }}
      </PanelHeading>
      <PanelBody>
        <p v-if="!changed.length" class="plan-compare__muted">
          {{ t("hangarPlanner.comparison.noChanges") }}
        </p>
        <ul class="plan-compare__changes">
          <li
            v-for="diff in changed"
            :key="diff.model.id"
            data-test="hangar-plan-compare-diff"
          >
            <Pill variant="neutral">
              {{ t(`hangarPlanner.changes.${diff.change}`) }}
            </Pill>
            {{ diff.model.name }}
            <span class="plan-compare__muted">
              {{ diff.leftCount }} → {{ diff.rightCount }}
            </span>
          </li>
        </ul>
      </PanelBody>
    </Panel>

    <Panel :variant="PanelVariantsEnum.SLIM" class="plan-compare__metrics">
      <PanelHeading compact divider>
        {{ t("hangarPlanner.metrics.title") }}
      </PanelHeading>
      <PanelBody>
        <MetricsTable
          :left="compare.metrics.left"
          :right="compare.metrics.right"
          :left-label="plan.name"
          :right-label="compare.otherPlanName"
        />
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.plan-compare {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
}

.plan-compare__metrics {
  grid-column: 1 / -1;
}

.plan-compare__totals {
  width: 100%;

  th,
  td {
    padding: 4px 8px;
    text-align: right;
  }

  th:first-child {
    text-align: left;
    font-weight: normal;
    color: var(--color-text-dim);
  }
}

.plan-compare__changes {
  margin: 0;
  padding: 0;
  list-style: none;

  li {
    padding: 2px 0;
  }
}

.plan-compare__muted {
  color: var(--color-text-dim);
}
</style>
