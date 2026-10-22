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

// A length difference says little next to the two lengths themselves, so
// those tiles show no difference.
const withoutDelta: ScalarKey[] = ["largestShip", "smallestShip"];

const format = (key: ScalarKey, value?: number | null) => {
  if (value === null || value === undefined) return "–";
  if (key === "totalPledgeValue") return amount(value);
  if (withoutDelta.includes(key)) return toNumber(value, "distance");
  return toNumber(value);
};

const signed = (key: ScalarKey, delta: number) => {
  const size =
    key === "totalPledgeValue"
      ? amount(Math.abs(delta))
      : toNumber(Math.abs(delta));
  return `${delta > 0 ? "+" : "−"}${size}`;
};

const tiles = computed(() =>
  scalarKeys.map((key) => {
    const before = props.left[key];
    const after = props.right[key];
    const delta =
      typeof before === "number" && typeof after === "number"
        ? after - before
        : 0;

    return {
      key,
      before: format(key, before),
      after: format(key, after),
      changed: before !== after,
      delta:
        delta && !withoutDelta.includes(key)
          ? { label: signed(key, delta), up: delta > 0 }
          : undefined,
    };
  }),
);

// Every group value either side holds, so a class the plan drops still shows
// as going to zero.
const groupRows = (key: "classifications" | "sizes" | "productionStatuses") => {
  const names = new Set([
    ...props.left[key].map((entry) => entry.name),
    ...props.right[key].map((entry) => entry.name),
  ]);
  const count = (side: HangarPlanMetrics, name: string) =>
    side[key].find((entry) => entry.name === name)?.count ?? 0;

  return [...names]
    .map((name) => ({
      name,
      label: name.replace(/[-_]/g, " "),
      before: count(props.left, name),
      after: count(props.right, name),
    }))
    .sort((a, b) => b.after - a.after || a.label.localeCompare(b.label));
};

const groups = computed(() =>
  (["classifications", "sizes", "productionStatuses"] as const)
    .map((key) => ({ key, rows: groupRows(key) }))
    .filter((group) => group.rows.length),
);
</script>

<template>
  <div class="plan-metrics" data-test="hangar-plan-metrics">
    <p class="plan-metrics__legend">
      {{ leftLabel }}
      <i class="fa-light fa-arrow-right" aria-hidden="true" />
      {{ rightLabel }}
    </p>

    <ul class="plan-metrics__tiles">
      <li
        v-for="tile in tiles"
        :key="tile.key"
        class="plan-metrics__tile"
        :class="{ 'plan-metrics__tile--changed': tile.changed }"
      >
        <span class="plan-metrics__label">
          {{ t(`hangarPlanner.metrics.${tile.key}`) }}
        </span>
        <span class="plan-metrics__values">
          <span class="plan-metrics__before">{{ tile.before }}</span>
          <i class="fa-light fa-arrow-right" aria-hidden="true" />
          <strong>{{ tile.after }}</strong>
        </span>
        <span
          v-if="tile.delta"
          class="plan-metrics__delta"
          :class="{ 'plan-metrics__delta--down': !tile.delta.up }"
        >
          {{ tile.delta.label }}
        </span>
      </li>
    </ul>

    <section
      v-for="group in groups"
      :key="group.key"
      class="plan-metrics__group"
    >
      <h4>{{ t(`hangarPlanner.metrics.${group.key}`) }}</h4>
      <ul>
        <li
          v-for="row in group.rows"
          :key="row.name"
          :class="{ 'plan-metrics__chip--changed': row.before !== row.after }"
          class="plan-metrics__chip"
        >
          <span class="plan-metrics__chip-name">{{ row.label }}</span>
          <span class="plan-metrics__before">{{ row.before }}</span>
          <i class="fa-light fa-arrow-right" aria-hidden="true" />
          <strong>{{ row.after }}</strong>
        </li>
      </ul>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.plan-metrics {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.plan-metrics__legend {
  display: flex;
  gap: 8px;
  align-items: center;
  margin: 0;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);

  i {
    color: var(--color-muted);
  }
}

.plan-metrics__tiles {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.plan-metrics__tile {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px 14px;
  border: 1px solid var(--color-edge-faint);
  border-radius: 8px;
  background: var(--color-gray-black);
}

.plan-metrics__tile--changed {
  border-color: var(--color-edge);
}

.plan-metrics__label {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.plan-metrics__values {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: baseline;

  strong {
    font-size: 1.05rem;
    color: var(--color-lifted);
  }

  i {
    font-size: 0.7rem;
    color: var(--color-muted);
  }
}

.plan-metrics__before {
  color: var(--color-text-dim);
}

.plan-metrics__delta {
  align-self: flex-start;
  padding: 1px 6px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--color-primary) 20%, transparent);
  color: var(--color-primary-tint);
  font-size: 0.75rem;
  font-weight: 600;
}

.plan-metrics__delta--down {
  background: rgba(122, 130, 136, 0.18);
  color: var(--color-text);
}

.plan-metrics__group {
  h4 {
    margin: 0 0 8px;
    font-size: 0.9rem;
    font-weight: 400;
    color: var(--color-text-dim);
  }

  ul {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin: 0;
    padding: 0;
    list-style: none;
  }
}

.plan-metrics__chip {
  display: inline-flex;
  gap: 6px;
  align-items: baseline;
  padding: 4px 10px;
  border: 1px solid var(--color-edge-faint);
  border-radius: 8px;
  font-size: 0.85rem;

  strong {
    color: var(--color-lifted);
  }

  i {
    font-size: 0.65rem;
    color: var(--color-muted);
  }
}

.plan-metrics__chip--changed {
  border-color: var(--color-edge);
}

.plan-metrics__chip-name {
  text-transform: capitalize;
}
</style>
