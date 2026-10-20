<script lang="ts">
export default {
  name: "HangarPlannerMetricsTable",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import type { HangarPlanMetrics } from "@/services/fyApi";

type Props = {
  left: HangarPlanMetrics;
  right: HangarPlanMetrics;
  leftLabel: string;
  rightLabel: string;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();
const { amount } = usePlanMoney();

type ScalarKey = Exclude<
  keyof HangarPlanMetrics,
  "classifications" | "sizes" | "productionStatuses" | "manufacturers"
>;

const metric = (key: ScalarKey, side: HangarPlanMetrics) => {
  const value = side[key];
  if (value === null || value === undefined) return "-";
  if (key === "totalPledgeValue") return amount(value);
  if (key === "largestShip" || key === "smallestShip") {
    return toNumber(value, "distance");
  }
  return toNumber(value);
};

const scalarKeys: ScalarKey[] = [
  "total",
  "uniqueModelsCount",
  "manufacturerCount",
  "flightReadyCount",
  "totalCrew",
  "totalCargo",
  "totalPledgeValue",
  "largestShip",
  "smallestShip",
];

// One row per group value either side has, so a class the plan drops still
// shows as a zero next to what the hangar holds.
const groupRows = (key: "classifications" | "sizes" | "productionStatuses") => {
  const names = new Set([
    ...props.left[key].map((entry) => entry.name),
    ...props.right[key].map((entry) => entry.name),
  ]);
  const count = (side: HangarPlanMetrics, name: string) =>
    side[key].find((entry) => entry.name === name)?.count ?? 0;

  return [...names].sort().map((name) => ({
    name,
    left: count(props.left, name),
    right: count(props.right, name),
  }));
};

const groups = computed(() =>
  (["classifications", "sizes", "productionStatuses"] as const).map((key) => ({
    key,
    rows: groupRows(key),
  })),
);
</script>

<template>
  <table class="plan-metrics" data-test="hangar-plan-metrics">
    <thead>
      <tr>
        <th />
        <th>{{ leftLabel }}</th>
        <th>{{ rightLabel }}</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="key in scalarKeys" :key="key">
        <th>{{ t(`hangarPlanner.metrics.${key}`) }}</th>
        <td>{{ metric(key, left) }}</td>
        <td :class="{ changed: left[key] !== right[key] }">
          {{ metric(key, right) }}
        </td>
      </tr>
    </tbody>
    <template v-for="group in groups" :key="group.key">
      <tbody v-if="group.rows.length">
        <tr class="plan-metrics__group">
          <th colspan="3">{{ t(`hangarPlanner.metrics.${group.key}`) }}</th>
        </tr>
        <tr v-for="row in group.rows" :key="row.name">
          <th>{{ row.name }}</th>
          <td>{{ row.left }}</td>
          <td :class="{ changed: row.left !== row.right }">{{ row.right }}</td>
        </tr>
      </tbody>
    </template>
  </table>
</template>

<style lang="scss" scoped>
.plan-metrics {
  width: 100%;
  border-collapse: collapse;

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

  thead th {
    color: var(--color-text-dim);
  }

  .changed {
    color: var(--color-primary);
    font-weight: 600;
  }
}

.plan-metrics__group th {
  padding-top: 12px;
  color: var(--color-text);
  font-weight: 600;
}
</style>
