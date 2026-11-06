<script lang="ts">
export default {
  name: "ModelHardpointsMinimal",
};
</script>

<script lang="ts" setup>
import CategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import { HARDPOINT_COLUMNS } from "@/frontend/components/Models/Hardpoints/columns";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { emptySplits } from "@/frontend/composables/powerSim";
import {
  useEquippedHardpoints,
  type EquippedModules,
} from "@/frontend/composables/useEquippedHardpoints";
import { useLoadoutSim } from "@/frontend/composables/useLoadoutSim";
import { useLoadoutStats } from "@/frontend/composables/useLoadoutStats";
import { useShieldStats } from "@/frontend/composables/useShieldStats";
import {
  HardpointCategoryEnum,
  HardpointGroupEnum,
  HardpointSourceEnum,
  useModelHardpoints as useModelHardpointsQuery,
  type CargoHold,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Loader from "@/shared/components/Loader/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import HardpointsMinimalRow from "./Row/index.vue";
import { minimalCategories, type MinimalCategory } from "./rows";

interface Props {
  model: Model;
  cargoHolds?: CargoHold[];
}

const props = withDefaults(defineProps<Props>(), {
  cargoHolds: () => [],
});

const { t, toNumber } = useI18n();

// Only flight-ready ships have game files, and every figure is derived from
// them. The others still have a slot list from the ship matrix.
const source = computed(() =>
  props.model.inGame
    ? HardpointSourceEnum.GAME_FILES
    : HardpointSourceEnum.SHIP_MATRIX,
);

const queryParams = computed(() => ({ source: source.value }));

const {
  isLoading,
  isFetching: loading,
  data: hardpoints,
} = useModelHardpointsQuery(
  computed(() => props.model.slug),
  queryParams,
);

const equippedModules = inject<Ref<EquippedModules>>(
  "equippedModules",
  ref({}),
);

const fitted = useEquippedHardpoints(
  () => hardpoints.value as Hardpoint[] | undefined,
  equippedModules,
);

const weaponPoolSize = () => props.model.metrics?.weaponPoolSize;
const regenModifier = computed(() => props.model.metrics?.weaponRegenModifier);
const autoPower = emptySplits().SCM;

const combat = useLoadoutStats(
  fitted,
  weaponPoolSize,
  () => autoPower,
  regenModifier,
);

// Auto power, the same split the full section opens on, so both views agree on
// the ship's shield until a reader moves a pip there.
const power = useLoadoutSim(
  fitted,
  weaponPoolSize,
  () => "SCM",
  () => autoPower,
  undefined,
  regenModifier,
);

const shield = useShieldStats(fitted, () => power.value.shieldPoolRatio);

provide("weaponRegenModifier", regenModifier);
provide(
  "weaponPowerRatio",
  computed(() => combat.value.weaponPowerRatio),
);

interface Figure {
  key: string;
  label: string;
  value: string;
  unit?: string;
}

const number = (value: number) =>
  String(toNumber(Math.round(value), "integer"));

const speed = (value: number) => String(toNumber(Math.round(value), "speed"));

const figures = computed<Figure[]>(() => {
  if (!props.model.inGame) {
    return [];
  }

  const { metrics, speeds } = props.model;
  const list: Figure[] = [];

  // Held open until the hardpoints first arrive, so the row does not jump then.
  // A refetch keeps the figures it has.
  const derived = (key: string, label: string, raw: number, unit: string) => {
    if (isLoading.value) {
      list.push({ key, label, value: "–" });
    } else if (raw) {
      list.push({ key, label, value: number(raw), unit });
    }
  };

  derived("dps", t("labels.combat.dps"), combat.value.dps.total, "DPS");

  if (!isLoading.value && combat.value.missileDamage) {
    list.push({
      key: "missiles",
      label: t("labels.combat.missileDamage"),
      value: number(combat.value.missileDamage),
      unit: "DMG",
    });
  }

  derived("shield", t("labels.defense.shieldHp"), shield.value.totalHp, "HP");

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

const categoriesFor = (group: HardpointGroupEnum): MinimalCategory[] =>
  minimalCategories(
    (fitted.value ?? []).filter((hardpoint) => hardpoint.group === group),
  );

const columns = computed(() =>
  HARDPOINT_COLUMNS.map((groups) =>
    groups
      .map((group) => ({ group, categories: categoriesFor(group) }))
      .filter(({ categories }) => categories.length),
  ).filter((column) => column.length),
);

const hasRows = computed(() => columns.value.some((column) => column.length));

const categoryLabel = (category: HardpointCategoryEnum) =>
  category === HardpointCategoryEnum.WEAPONS
    ? t("labels.hardpoints.guns")
    : t(`labels.hardpoint.categories.${category}`);
</script>

<template>
  <div
    id="hardpoints"
    class="hardpoints-minimal"
    data-test="hardpoints-minimal"
  >
    <Panel
      v-if="figures.length"
      :outer-spacing="false"
      :loading="loading"
      class="hardpoints-minimal__figures"
    >
      <PanelBody>
        <div class="metrics-card__hero">
          <div
            v-for="figure in figures"
            :key="figure.key"
            class="metrics-card__tile"
            :data-test="`hardpoints-minimal-figure-${figure.key}`"
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

    <div
      class="hardpoints-minimal__list"
      :class="{ 'hardpoints-minimal__list--loading': loading }"
    >
      <Loader :loading="loading" />
      <div v-if="hasRows" class="hardpoints-minimal__columns">
        <div
          v-for="(column, index) in columns"
          :key="index"
          class="hardpoints-minimal__column"
        >
          <MetricsCard
            v-for="{ group, categories } in column"
            :key="group"
            variant="slim"
            :title="t(`labels.hardpoint.groups.${group.toLowerCase()}`)"
          >
            <div
              v-for="{ category, rows } in categories"
              :key="category"
              class="hardpoints-minimal__category"
              :class="{ 'hardpoints-minimal__category--bare': rows[0]?.total }"
            >
              <div
                v-if="!rows[0]?.total"
                class="hardpoints-minimal__category-label"
              >
                <CategoryIcon
                  :category="category"
                  class="hardpoints-minimal__category-icon"
                />
                {{ categoryLabel(category) }}
              </div>
              <HardpointsMinimalRow
                v-for="row in rows"
                :key="row.key"
                :row="row"
              />
            </div>
          </MetricsCard>
        </div>
      </div>
      <Empty
        v-else-if="!loading"
        :name="t('resources.hardpoints')"
        :variant="EmptyVariantsEnum.BOX"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.hardpoints-minimal {
  &__figures {
    margin-bottom: 20px;

    .metrics-card__hero {
      margin-bottom: 0;
    }
  }

  &__list {
    position: relative;
  }

  &__list--loading {
    min-height: 160px;
  }

  &__columns {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    column-gap: 20px;

    @media (min-width: map-get($grid-breakpoints, md)) {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    // Short rows fit three columns well before the full list's breakpoint.
    @media (min-width: 1200px) {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }
  }

  &__category {
    margin-top: 10px;

    &:first-child {
      margin-top: 0;
    }
  }

  &__category--bare {
    margin-top: 0;
  }

  &__category-label {
    --hardpoint-category-icon-size: 16px;

    display: flex;
    align-items: center;
    gap: 6px;
    margin-bottom: 2px;
    color: var(--color-text-dim);
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.625rem;
    letter-spacing: 0.16em;
    text-transform: uppercase;
  }

  &__category-icon {
    color: var(--color-muted);
  }
}
</style>
