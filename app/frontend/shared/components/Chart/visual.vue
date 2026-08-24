<script lang="ts">
export default {
  name: "VisualTestsChartsPage",
};
</script>

<script lang="ts" setup>
import Chart from "@/shared/components/Chart/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import type { BarChartStats, PieChartStats } from "@/services/fyApi";

/*
 * Chart takes its whole lifecycle through one `asyncStatus` bag of refs, so a
 * demo can drive every state without a query behind it. Built by hand rather
 * than by mocking a request: the states worth looking at are the ones a real
 * fetch reaches only briefly, or not at all.
 */
const status = (overrides: Partial<AsyncStatus> = {}): AsyncStatus => ({
  fetchStatus: ref("idle"),
  isError: ref(false),
  isPending: ref(false),
  isLoading: ref(false),
  isFetching: ref(false),
  isRefetching: ref(false),
  error: ref(null),
  ...overrides,
});

const settled = status();

const pending = status({
  fetchStatus: ref("fetching"),
  isPending: ref(true),
  isFetching: ref(true),
  isLoading: ref(true),
});

// Carries a refetch so the retry button is on screen; clearing the error is what
// a successful retry would amount to here.
const failedError = ref<Error | null>(new Error("the request failed"));

const failed = status({
  isError: ref(true),
  error: failedError,
  refetch: () => {
    failedError.value = null;
  },
});

// A background refetch must keep the drawn chart on screen. If this one shows a
// spinner the `reload` interval flashes over a chart that is already there.
const refetching = status({
  fetchStatus: ref("fetching"),
  isFetching: ref(true),
  isRefetching: ref(true),
});

const bars: BarChartStats[] = [
  { label: "Aegis Dynamics", count: 34, tooltip: "34 ships" },
  { label: "Anvil Aerospace", count: 28, tooltip: "28 ships" },
  { label: "Roberts Space Industries", count: 21, tooltip: "21 ships" },
  { label: "Origin Jumpworks", count: 17, tooltip: "17 ships" },
  { label: "Drake Interplanetary", count: 12, tooltip: "12 ships" },
  { label: "MISC", count: 9, tooltip: "9 ships" },
];

// One flat series. A column of equal values used to read as a missing chart,
// so it is worth having on screen next to the varied one.
const flat: BarChartStats[] = [
  { label: "Jan", count: 5, tooltip: "5 ships" },
  { label: "Feb", count: 5, tooltip: "5 ships" },
  { label: "Mar", count: 5, tooltip: "5 ships" },
  { label: "Apr", count: 5, tooltip: "5 ships" },
];

const slices: PieChartStats[] = [
  { name: "Combat", y: 41, selected: false, sliced: false },
  { name: "Transport", y: 26, selected: false, sliced: false },
  { name: "Exploration", y: 18, selected: false, sliced: true },
  { name: "Industrial", y: 9, selected: false, sliced: false },
  { name: "Support", y: 6, selected: false, sliced: false },
];

// A single slice is the case where a pie has no shape to compare against.
const oneSlice: PieChartStats[] = [
  { name: "Combat", y: 100, selected: false, sliced: false },
];

const redrawKey = ref(0);

const redraw = () => {
  redrawKey.value += 1;
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Types</Heading>
  <p>
    The five Highcharts types the component accepts. Bar, line, column and area
    read their categories from <code>label</code>; pie reads
    <code>name</code> and <code>y</code>.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Chart
        :key="`bar-${redrawKey}`"
        name="vt-bar"
        type="bar"
        :async-status="settled"
        :options="bars"
        tooltip-type="ship"
        :height="300"
      />
    </div>
    <div class="col-12 col-lg-6">
      <Chart
        :key="`column-${redrawKey}`"
        name="vt-column"
        type="column"
        :async-status="settled"
        :options="bars"
        tooltip-type="ship"
        :height="300"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Chart
        :key="`line-${redrawKey}`"
        name="vt-line"
        type="line"
        :async-status="settled"
        :options="bars"
        tooltip-type="ship"
        :height="300"
      />
    </div>
    <div class="col-12 col-lg-6">
      <Chart
        :key="`area-${redrawKey}`"
        name="vt-area"
        type="area"
        :async-status="settled"
        :options="bars"
        tooltip-type="ship"
        :height="300"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Chart
        :key="`pie-${redrawKey}`"
        name="vt-pie"
        type="pie"
        :async-status="settled"
        :options="slices"
        tooltip-type="ship-pie"
        :height="300"
      />
    </div>
    <div class="col-12 col-lg-6">
      <Chart
        :key="`pie-one-${redrawKey}`"
        name="vt-pie-one"
        type="pie"
        :async-status="settled"
        :options="oneSlice"
        tooltip-type="ship-pie"
        :height="300"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">A flat series</Heading>
  <p>
    Equal values across every category. The axis has to start at zero for this
    to read as data rather than as a chart that failed to draw.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Chart
        :key="`flat-${redrawKey}`"
        name="vt-flat"
        type="column"
        :async-status="settled"
        :options="flat"
        tooltip-type="ship"
        :height="300"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Async states</Heading>
  <p>
    Each box keeps its <code>height</code> from the first paint, so the panel
    around it does not snap open when the data lands.
  </p>
  <div class="row">
    <div class="col-12 col-lg-4">
      <p class="text-muted">Pending — spinner over the reserved height.</p>
      <Chart
        name="vt-pending"
        type="column"
        :async-status="pending"
        :options="bars"
        :height="260"
      />
    </div>
    <div class="col-12 col-lg-4">
      <p class="text-muted">
        Failed — no axis frame is drawn, and the box says why rather than
        sitting empty. With a <code>refetch</code> on the status it offers a
        retry.
      </p>
      <Chart
        name="vt-failed"
        type="column"
        :async-status="failed"
        :options="bars"
        :height="260"
      />
    </div>
    <div class="col-12 col-lg-4">
      <p class="text-muted">
        Refetching — the drawn chart stays and no spinner appears.
      </p>
      <Chart
        :key="`refetching-${redrawKey}`"
        name="vt-refetching"
        type="column"
        :async-status="refetching"
        :options="bars"
        :height="260"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">No data</Heading>
  <p>
    Settled with an empty series. Left to Highcharts this drew a bare pair of
    axes, which reads as a chart that failed rather than one with nothing to
    plot, so the component says so instead.
  </p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Chart
        :key="`empty-${redrawKey}`"
        name="vt-empty"
        type="column"
        :async-status="settled"
        :options="[]"
        :height="260"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Admin theme</Heading>
  <p>The same series on the admin palette.</p>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Chart
        :key="`admin-${redrawKey}`"
        name="vt-admin"
        type="column"
        :async-status="settled"
        :options="bars"
        tooltip-type="ship"
        admin
        :height="300"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Redraw</Heading>
  <p>
    Remounts every chart above. Highcharts holds its own instance outside Vue's
    control, so a chart surviving a remount is worth being able to check by
    hand.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn data-test="charts-redraw" @click="redraw">Redraw all</Btn>
    </div>
  </div>
</template>
