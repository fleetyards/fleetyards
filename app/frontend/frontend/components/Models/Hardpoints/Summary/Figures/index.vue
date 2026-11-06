<script lang="ts">
export default {
  name: "HardpointsSummaryFigures",
};
</script>

<script lang="ts" setup>
import { type EquippedModules } from "@/frontend/composables/useEquippedHardpoints";
import { type CargoHold, type Model } from "@/services/fyApi";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  model: Model;
  cargoHolds?: CargoHold[];
  dps?: number;
  missileDamage?: number;
  shieldHp?: number;
  // In flight, first answer or refetch alike.
  loading?: boolean;
  // No answer yet, so the figures read off the hardpoints have nothing to show.
  pending?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  cargoHolds: () => [],
  dps: 0,
  missileDamage: 0,
  shieldHp: 0,
  loading: false,
  pending: false,
});

interface Figure {
  key: string;
  label: string;
  value: string;
  unit?: string;
}

const { t, toNumber } = useI18n();

const equippedModules = inject<Ref<EquippedModules>>(
  "equippedModules",
  ref({}),
);

const number = (value: number) =>
  String(toNumber(Math.round(value), "integer"));

const speed = (value: number) => String(toNumber(Math.round(value), "speed"));

const figures = computed<Figure[]>(() => {
  const { metrics, speeds } = props.model;
  const list: Figure[] = [];

  // Held open until the hardpoints first arrive, so the row does not jump then.
  // A refetch keeps the figures it has.
  const derived = (key: string, label: string, raw: number, unit: string) => {
    if (props.pending) {
      list.push({ key, label, value: "–" });
    } else if (raw) {
      list.push({ key, label, value: number(raw), unit });
    }
  };

  derived("dps", t("labels.combat.dps"), props.dps, "DPS");

  if (!props.pending && props.missileDamage) {
    list.push({
      key: "missiles",
      label: t("labels.combat.missileDamage"),
      value: number(props.missileDamage),
      unit: "DMG",
    });
  }

  derived("shield", t("labels.defense.shieldHp"), props.shieldHp, "HP");

  if (metrics?.hullHealth) {
    list.push({
      key: "hull",
      label: t("labels.hull.hullHp"),
      value: number(metrics.hullHealth),
      unit: "HP",
    });
  }

  if (metrics?.isGroundVehicle) {
    if (speeds?.groundMaxSpeed) {
      list.push({
        key: "ground",
        label: t("model.groundMaxSpeed"),
        value: speed(speeds.groundMaxSpeed),
      });
    }
  } else {
    if (speeds?.scmSpeed) {
      list.push({
        key: "scm",
        label: t("model.scmSpeed"),
        value: speed(speeds.scmSpeed),
      });
    }
    if (speeds?.scmSpeedBoosted) {
      list.push({
        key: "boost",
        label: t("labels.flight.boost"),
        value: speed(speeds.scmSpeedBoosted),
      });
    }
    if (speeds?.maxSpeed) {
      list.push({
        key: "max",
        label: t("model.maxSpeed"),
        value: speed(speeds.maxSpeed),
      });
    }
  }

  // The figure the page's base metrics show, until a picked module changes what
  // the holds add up to.
  const pickedModule = Object.values(equippedModules.value).some(Boolean);
  const cargo = pickedModule
    ? props.cargoHolds.reduce((sum, hold) => sum + (hold.capacity || 0), 0)
    : (metrics?.maxCargo ?? metrics?.cargo);

  if (cargo) {
    list.push({
      key: "cargo",
      label: t("model.cargo"),
      value: number(cargo),
      unit: "SCU",
    });
  }

  return list;
});

// Two even rows between a phone and room for them all on one line, however many
// figures the ship has: a fixed share left a lone tile stretched across a row.
const figuresPerRow = computed(() => {
  const count = figures.value.length;

  return count > 4 ? Math.ceil(count / 2) : count;
});
</script>

<template>
  <Panel
    v-if="figures.length"
    :outer-spacing="false"
    :loading="loading"
    class="summary-figures"
    data-test="hardpoints-summary-figures"
  >
    <PanelBody>
      <div
        class="metrics-card__hero"
        :style="{ '--summary-figures-per-row': figuresPerRow }"
      >
        <div
          v-for="figure in figures"
          :key="figure.key"
          class="metrics-card__tile"
          :data-test="`hardpoints-summary-figure-${figure.key}`"
        >
          <div class="metrics-card__tile__label">{{ figure.label }}</div>
          <div class="metrics-card__tile__value">
            {{ figure.value }}
            <span v-if="figure.unit" class="metrics-card__tile__unit">
              {{ figure.unit }}
            </span>
          </div>
        </div>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.summary-figures {
  margin-bottom: 20px;

  .metrics-card__hero {
    margin-bottom: 0;
  }

  @media (min-width: 640px) and (max-width: 1359.98px) {
    .metrics-card__tile {
      flex: 1 1 calc(100% / var(--summary-figures-per-row) - 1px);
    }
  }
}
</style>
