<script lang="ts">
export default {
  name: "HangarPlannerSummaryPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Alert from "@/shared/components/base/Alert/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import type { HangarPlanSummary } from "@/services/fyApi";

type Props = {
  summary?: HangarPlanSummary;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  summary: undefined,
  loading: false,
});

const { t } = useI18n();
const { amount, range } = usePlanMoney();

const totals = computed(() => props.summary?.totals);

const rows = computed(() => {
  if (!totals.value) return [];

  const value = totals.value;

  return [
    { key: "spend", value: range(value.spendMin, value.spendMax) },
    {
      key: "meltCredit",
      value: amount(value.meltCredit),
      note: value.estimatedMeltsCount
        ? t("hangarPlanner.summary.estimatedMelts", {
            count: value.estimatedMeltsCount,
          })
        : undefined,
    },
    { key: "startingCredit", value: amount(value.startingCredit) },
    { key: "net", value: range(value.netMin, value.netMax) },
    {
      key: "cashNeeded",
      value: range(value.cashNeededMin, value.cashNeededMax),
    },
    {
      key: "remainingCredit",
      value: range(value.remainingCreditMin, value.remainingCreditMax),
    },
  ];
});

const gaps = computed(() => {
  if (!totals.value) return [];

  return [
    { key: "openSlots", count: totals.value.openSlotsCount },
    { key: "undecidedSlots", count: totals.value.undecidedSlotsCount },
    { key: "unresolved", count: totals.value.unresolvedCount },
  ].filter((gap) => gap.count > 0);
});
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    :loading="loading"
    data-test="hangar-plan-summary"
  >
    <PanelHeading compact divider>
      {{ t("hangarPlanner.summary.title") }}
    </PanelHeading>
    <PanelBody>
      <dl v-if="totals" class="plan-summary">
        <template v-for="row in rows" :key="row.key">
          <dt>{{ t(`hangarPlanner.summary.${row.key}`) }}</dt>
          <dd :data-test="`hangar-plan-summary-${row.key}`">
            {{ row.value }}
            <small v-if="row.note">{{ row.note }}</small>
          </dd>
        </template>
      </dl>

      <ul v-if="gaps.length" class="plan-summary__gaps">
        <li v-for="gap in gaps" :key="gap.key">
          {{ t(`hangarPlanner.summary.${gap.key}`, { count: gap.count }) }}
        </li>
      </ul>

      <Alert
        v-if="summary?.issues.length"
        variant="warning"
        :title="t('hangarPlanner.summary.incomplete')"
      >
        <ul class="plan-summary__issues">
          <li
            v-for="issue in summary.issues"
            :key="`${issue.kind}-${issue.name}`"
          >
            {{ t(`hangarPlanner.issues.${issue.kind}`, { name: issue.name }) }}
          </li>
        </ul>
      </Alert>
      <p v-else-if="totals?.complete" class="plan-summary__complete">
        <i class="fa-duotone fa-circle-check" />
        {{ t("hangarPlanner.summary.complete") }}
      </p>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.plan-summary {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 4px 16px;
  margin: 0;

  dt {
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    text-align: right;

    small {
      display: block;
      color: var(--color-text-dim);
    }
  }
}

.plan-summary__gaps,
.plan-summary__issues {
  margin: 12px 0 0;
  padding-left: 16px;
}

.plan-summary__gaps {
  color: var(--color-warning);
}

.plan-summary__complete {
  margin: 12px 0 0;
  color: var(--color-success);
}
</style>
