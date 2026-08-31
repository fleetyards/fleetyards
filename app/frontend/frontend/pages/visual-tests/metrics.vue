<script lang="ts">
export default {
  name: "VisualTestsMetricsPage",
};

// The shape ModelMetricRows takes, written out rather than derived from a model:
// the point of the demo is the layout rules, not the data behind them.
const metricRowGroups = [
  {
    split: true,
    rows: [
      { label: "Length", value: "242.0 m" },
      { label: "Beam", value: "136.0 m" },
      { label: "Height", value: "42.0 m" },
      { label: "Mass", value: "6,000,000 kg" },
    ],
  },
  {
    rows: [
      { label: "Focus", value: "Capital" },
      { label: "Crew", value: "8 – 12" },
    ],
  },
];

// A group with nothing in it is not a group: rendering it left an empty box with
// a divider under it, so the component filters those out.
const metricRowGroupsWithEmpty = [
  metricRowGroups[0],
  { rows: [] },
  metricRowGroups[1],
];
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import MetricsList from "@/shared/components/MetricsList/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import MissingRolesPanel from "@/shared/components/MissingRolesPanel/index.vue";
import ModelMetricRows from "@/shared/components/ModelMetricRows/index.vue";
import ModelBaseMetrics from "@/frontend/components/Models/BaseMetrics/index.vue";
import ModelCrewMetrics from "@/frontend/components/Models/CrewMetrics/index.vue";
import ModelSpeedMetrics from "@/frontend/components/Models/SpeedMetrics/index.vue";
import ModelCargoMetrics from "@/frontend/components/Models/CargoMetrics/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import ModelCombatMetrics from "@/frontend/components/Models/CombatMetrics/index.vue";
import ModelDefenseMetrics from "@/frontend/components/Models/DefenseMetrics/index.vue";
import ModelHullMetrics from "@/frontend/components/Models/HullMetrics/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  HardpointSourceEnum,
  useModel as useModelQuery,
  useModelHardpoints as useModelHardpointsQuery,
  type Hardpoint,
} from "@/services/fyApi";

// An in-game combat ship, so the combat, survivability and hull cards all have
// something to render — a concept ship has no game-file hardpoints and they all
// self-hide.
const SLUG = "rsi-constellation-andromeda";

const { data: model } = useModelQuery(SLUG);

const hardpointsParams = computed(() => ({
  source: model.value?.inGame
    ? HardpointSourceEnum.GAME_FILES
    : HardpointSourceEnum.SHIP_MATRIX,
}));

const { data: hardpointsData, isLoading: hardpointsLoading } =
  useModelHardpointsQuery(SLUG, hardpointsParams);

const hardpoints = computed(
  () => (hardpointsData.value as Hardpoint[] | undefined) || [],
);

provide(
  "modelSlug",
  computed(() => SLUG),
);

provide(
  "weaponPoolSize",
  computed(() => model.value?.metrics?.weaponPoolSize),
);

provide(
  "quantumFuelTankSize",
  computed(() => model.value?.metrics?.quantumFuelTankSize),
);

const extended = ref(false);

const toggleExtended = () => {
  extended.value = !extended.value;
};

const sampleMetrics = [
  { id: "length", label: "Length", value: "128.0 m" },
  { id: "beam", label: "Beam", value: "70.0 m" },
  { id: "height", label: "Height", value: "26.5 m" },
  { id: "mass", label: "Mass", value: "3,568,000 kg" },
];
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">MetricsCard | Frame</Heading>
  <p>
    The bare card frame — title with status dot, optional <code>head</code> slot
    and a body slot. The default variant carries the end caps; the
    <code>slim</code> variant drops them for repeated cards (hardpoint groups).
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <MetricsCard title="Default Variant">
        Body content goes here. The frame makes no assumptions about what it
        wraps.
      </MetricsCard>
    </div>
    <div class="col-12 col-lg-6">
      <MetricsCard title="With Head Slot">
        <template #head>
          <Btn>
            <i class="fa-duotone fa-arrow-up-right-from-square" />
          </Btn>
        </template>
        The <code>head</code> slot sits next to the title — used for card-level
        actions.
      </MetricsCard>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <MetricsCard title="Slim Variant" variant="slim">
        No end caps, thinner border, header divider.
      </MetricsCard>
    </div>
    <div class="col-12 col-lg-6">
      <MetricsCard title="Slim | Stacked" variant="slim">
        Slim cards are meant to repeat, so their bottom margin is tighter.
      </MetricsCard>
      <MetricsCard title="Slim | Stacked" variant="slim">
        A second card, to check the rhythm between them.
      </MetricsCard>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2"
    >MetricsCard | Content Primitives</Heading
  >
  <p>
    The tile grid, auxiliary row, divider and footer classes that slotted card
    content uses. Tiles flex, so a card fills with however many are present.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <MetricsCard title="Three Tiles">
        <div class="metrics-card__hero">
          <div class="metrics-card__tile metrics-card__tile--primary">
            <div class="metrics-card__tile__label">Burst</div>
            <div class="metrics-card__tile__value">
              4,182
              <span class="metrics-card__tile__unit">DPS</span>
            </div>
            <div class="metrics-card__tile__sub">across 8 weapons</div>
          </div>
          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">Sustained</div>
            <div class="metrics-card__tile__value">
              2,904
              <span class="metrics-card__tile__unit">DPS</span>
            </div>
            <div class="metrics-card__tile__sub">with power throttle</div>
          </div>
          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">Alpha</div>
            <div class="metrics-card__tile__value">
              1,140
              <span class="metrics-card__tile__unit">DMG</span>
            </div>
            <div class="metrics-card__tile__sub">single volley</div>
          </div>
        </div>
        <div class="metrics-card__aux">
          <span class="metrics-card__aux-label">Missile Payload</span>
          <span class="metrics-card__aux-value">18,240</span>
        </div>
        <div class="metrics-card__divider" />
        <div class="metrics-card__section-label">Breakdown</div>
        <MetricsList :metrics="sampleMetrics" />
        <div class="metrics-card__footer">
          <button type="button" class="metrics-card__toggle">
            Show details
          </button>
          <span class="metrics-card__hint">
            Values are derived from game files.
          </span>
        </div>
      </MetricsCard>
    </div>
    <div class="col-12 col-lg-6">
      <MetricsCard title="Single Tile">
        <div class="metrics-card__hero">
          <div class="metrics-card__tile metrics-card__tile--primary">
            <div class="metrics-card__tile__label">Hull</div>
            <div class="metrics-card__tile__value">
              1,284,000
              <span class="metrics-card__tile__unit">HP</span>
            </div>
            <div class="metrics-card__tile__sub">
              six figures, to check clamping
            </div>
          </div>
        </div>
      </MetricsCard>
      <MetricsCard title="Six Tiles" variant="slim">
        <div class="metrics-card__hero">
          <div
            v-for="index in 6"
            :key="`tile-${index}`"
            class="metrics-card__tile"
          >
            <div class="metrics-card__tile__label">Stat {{ index }}</div>
            <div class="metrics-card__tile__value">
              {{ index * 137 }}
              <span class="metrics-card__tile__unit">u</span>
            </div>
          </div>
        </div>
      </MetricsCard>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">MetricsList</Heading>
  <p>
    Label/value pairs in two columns. The items are half-width with the value
    pushed right, so the pairs only read as pairs in a narrow container — the
    wide row below shows how far apart they drift at full width. It carries no
    padding of its own, so inside a panel it needs a
    <code>PanelBody</code> around it.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-4">
      <BaseText muted no-spacing>standalone, narrow</BaseText>
      <MetricsList :metrics="sampleMetrics" />
    </div>
    <div class="col-12 col-md-6 col-lg-4">
      <BaseText muted no-spacing>in a panel body</BaseText>
      <Panel>
        <PanelBody>
          <MetricsList :metrics="sampleMetrics" />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-lg-4">
      <BaseText muted no-spacing>empty — renders nothing</BaseText>
      <MetricsList :metrics="[]" />
    </div>
  </div>
  <div class="row">
    <div class="col-12">
      <BaseText muted no-spacing>standalone, full width</BaseText>
      <MetricsList :metrics="sampleMetrics" />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Model Metrics | Panel Rails</Heading>
  <p>
    The rail panels from the ship detail page, fed with live
    <code>{{ SLUG }}</code> data. Base and crew carry their own frame through
    <code>MetricsCard</code>; speed is bare rows, so it is the only one that
    needs a <code>Panel</code> around it.
    <Btn @click="toggleExtended">
      {{ extended ? "Collapse" : "Extend" }} dimensions
    </Btn>
  </p>
  <div v-if="model" class="row">
    <div class="col-12 col-lg-4">
      <ModelBaseMetrics :model="model" :extended="extended" />
    </div>
    <div class="col-12 col-lg-4">
      <ModelCrewMetrics :model="model" />
    </div>
    <div class="col-12 col-lg-4">
      <Panel>
        <ModelSpeedMetrics :model="model" />
      </Panel>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Model Metrics | Panel Summary</Heading>
  <p>The compact metrics block used inside model panels.</p>
  <div v-if="model" class="row">
    <div class="col-12 col-lg-6">
      <Panel>
        <ModelPanelMetrics :model="model" />
      </Panel>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Model Metrics | Cargo</Heading>
  <p>Container capacity per size, derived from the model's cargo holds.</p>
  <ModelCargoMetrics v-if="model" :model="model" />

  <Heading :level="HeadingLevelEnum.H2"
    >Model Metrics | Combat & Survivability</Heading
  >
  <p>
    The metrics-card family on the ship detail page, fed with the live game-file
    hardpoints of <code>{{ SLUG }}</code
    >.
    <template v-if="hardpointsLoading"> Loading hardpoints…</template>
  </p>
  <div v-if="model" class="row">
    <div class="col-12 col-lg-4">
      <ModelCombatMetrics :hardpoints="hardpoints" />
    </div>
    <div class="col-12 col-lg-4">
      <ModelDefenseMetrics :hardpoints="hardpoints" :model-name="model.name" />
    </div>
    <div class="col-12 col-lg-4">
      <ModelHullMetrics
        :hull-health="model.metrics.hullHealth"
        :hull-parts="model.metrics.hullParts"
        :hull-doors="model.metrics.hullDoors"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Model Metrics | No Data</Heading>
  <p>
    Combat, survivability and hull cards all self-hide when there is nothing to
    show — nothing should render below this line.
  </p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <ModelCombatMetrics :hardpoints="[]" />
    </div>
    <div class="col-12 col-lg-4">
      <ModelDefenseMetrics :hardpoints="[]" />
    </div>
    <div class="col-12 col-lg-4">
      <ModelHullMetrics />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Stats Panels</Heading>
  <p>
    The stats-grid tiles. MissingRolesPanel is the same tile with its detail
    carried as chips, so it lines up with its neighbours instead of reading as a
    headed panel of prose.
  </p>
  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-rocket fa-4x"
        :value="62"
        label="Total Ships"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-heart fa-4x"
        :value="8"
        label="Wishlist"
        suffix="(13%)"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <MissingRolesPanel :roles="['competition']" />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-coins fa-4x"
        :value="206.91"
        label="Hangar aUEC Value"
        suffix="M aUEC"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <MissingRolesPanel :roles="['competition', 'ground_vehicle']" />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <MissingRolesPanel
        :roles="[
          'competition',
          'exploration',
          'ground_vehicle',
          'multi_role',
          'support',
          'transport',
        ]"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-industry fa-4x"
        :value="12"
        label="Manufacturers"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">ModelMetricRows</Heading>
  <p>
    The row list behind the ship card's expanded details and the embed's card.
    <code>split</code> sets the two-up groups — dimensions and price — while the
    summary rows run full width.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Panel>
        <PanelBody>
          <ModelMetricRows :groups="metricRowGroups" />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>
        With an empty group in the middle — filtered out, not rendered as a gap
      </BaseText>
      <Panel>
        <PanelBody>
          <ModelMetricRows :groups="metricRowGroupsWithEmpty" />
        </PanelBody>
      </Panel>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <BaseText muted no-spacing>Nothing at all</BaseText>
      <Panel>
        <PanelBody>
          <ModelMetricRows :groups="[]" />
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>
