<script lang="ts">
export default {
  name: "ChartComponent",
};
</script>

<script lang="ts" setup>
import Highcharts from "highcharts";
import "highcharts/esm/modules/accessibility";
import type { PieChartStats, BarChartStats } from "@/services/fyApi";
import { v4 as uuidv4 } from "uuid";
import Loader from "@/shared/components/Loader/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useChartTheme } from "@/shared/composables/useChartTheme";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import { useI18n } from "@/shared/composables/useI18n";

type TooltipLabelOption = {
  label?: number | string;
  count?: number;
  percentage?: number;
};

type ChartData = PieChartStats | BarChartStats;

type Props = {
  name: string;
  asyncStatus: AsyncStatus;
  options?: ChartData[];
  type?: "line" | "bar" | "column" | "area" | "pie";
  reload?: number;
  tooltipType?: string;
  height?: number;
  admin?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  options: () => [],
  type: "line",
  tooltipType: "",
  reload: undefined,
  height: 400,
  admin: false,
});

const { t } = useI18n();

const chart = ref<HTMLElement | undefined>();

const uuid = ref(`chart-${uuidv4()}`);

const instance = ref<Highcharts.Chart | undefined>();

const interval = ref<NodeJS.Timeout | undefined>();

const { theme } = useChartTheme();

const chartWithCategory = computed(() => {
  return ["bar", "line", "column", "area"].includes(props.type);
});

const xAxis = computed(() => {
  if (chartWithCategory.value) {
    return {
      categories: (props.options as BarChartStats[]).map((item) => item.label),
    };
  }
  return {};
});

const yAxis = computed(() => {
  if (chartWithCategory.value) {
    return {
      allowDecimals: false,
    };
  }
  return {};
});

const legend = computed(() => {
  if (chartWithCategory.value) {
    return { enabled: false };
  }

  return theme.value.legend;
});

const chartData = computed(() => {
  if (chartWithCategory.value) {
    return (props.options as BarChartStats[]).map((item) => [
      item.tooltip,
      item.count,
    ]);
  }

  return props.options;
});

// A background refetch keeps the drawn chart on screen, so it must not read as
// loading - otherwise the `reload` interval flashes the spinner over a chart
// that is already there.
const loading = computed(() => {
  return (
    (props.asyncStatus.isPending?.value ||
      props.asyncStatus.isFetching?.value ||
      props.asyncStatus.isLoading?.value) &&
    !props.asyncStatus.isRefetching?.value
  );
});

const failed = computed(() => !!props.asyncStatus.error?.value);

/*
 * Settled with nothing to plot. Left to Highcharts this drew a bare pair of
 * axes, which reads as a chart that failed rather than as one with no data yet -
 * and the failure case drew nothing at all, so an empty box was the only thing
 * either state had to say.
 */
const empty = computed(
  () => !loading.value && !failed.value && !props.options.length,
);

const retry = () => {
  props.asyncStatus.refetch?.();
};

onMounted(() => {
  uuid.value = `chart-${uuidv4()}`;

  setupChart();

  if (props.reload) {
    interval.value = setInterval(() => {
      if (props.asyncStatus.refetch) {
        props.asyncStatus.refetch();
      }
    }, props.reload * 1000);
  }
});

const tooltipFormat = (tooltip: Highcharts.Point) => {
  const options: TooltipLabelOption = {
    label: tooltip.key,
    count: tooltip.y || undefined,
    percentage: undefined,
  };

  if (props.type === "pie") {
    options.percentage = Math.round(tooltip.percentage || 0);
  }

  return t(`chart.labels.${props.tooltipType}`, options);
};

watch(
  () => props.options,
  () => {
    if (instance.value) {
      reloadChart();
    } else {
      setupChart();
    }
  },
  {
    deep: true,
  },
);

watch(loading, () => {
  if (!instance.value) {
    setupChart();
  }
});

const reloadChart = () => {
  const series = instance.value?.series[0];

  if (!series) {
    return;
  }

  if (chartWithCategory.value) {
    series.setData(
      (props.options as BarChartStats[]).map((item) => [
        item.tooltip,
        item.count,
      ]),
    );

    instance.value?.xAxis[0].setCategories(
      (props.options as BarChartStats[]).map((item) => item.label || ""),
    );
  } else {
    series.setData(props.options);
  }
};

const setupChart = () => {
  // Drawing before the data lands would put a bare axis frame behind the
  // spinner, and drawing after an error would put one there for good.
  if (!chart.value || loading.value || failed.value) {
    return;
  }

  instance.value = Highcharts.chart(chart.value, {
    ...theme.value,
    chart: {
      ...theme.value.chart,
      type: props.type,
      height: props.height,
    },
    xAxis: {
      ...theme.value.xAxis,
      ...xAxis.value,
    },
    yAxis: {
      ...theme.value.yAxis,
      ...yAxis.value,
    },
    legend: legend.value,
    tooltip: {
      ...theme.value.tooltip,
      formatter() {
        return tooltipFormat(this);
      },
    },
    series: [
      {
        type: props.type,
        data: chartData.value,
      },
    ],
  });
};
</script>

<template>
  <!--
    The chart only gets its height once Highcharts has drawn it, so the box
    holds that height from the start - without it the panel collapses to the
    spinner and snaps open when the data lands.
  -->
  <div class="chart-container" :style="{ minHeight: `${height}px` }">
    <!--
      v-show, not v-if: setupChart needs the element to exist, and the ref has
      to survive a state change without being re-acquired.
    -->
    <div v-show="!failed && !empty" :id="uuid" ref="chart" class="chart" />

    <div v-if="failed" class="chart-state">
      <i class="fa-duotone fa-chart-line-down" />
      <span>{{ t("chart.states.failed") }}</span>
      <Btn v-if="asyncStatus.refetch" data-test="chart-retry" @click="retry">
        {{ t("chart.states.retry") }}
      </Btn>
    </div>
    <div v-else-if="empty" class="chart-state" data-test="chart-empty">
      <i class="fa-duotone fa-chart-simple" />
      <span>{{ t("chart.states.empty") }}</span>
    </div>

    <Loader :loading="loading" :admin="admin" relative />
  </div>
</template>

<style scoped>
.chart-container {
  position: relative;
}

/* Centred in the height the container already reserves for the chart. */
.chart-state {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  text-align: center;
}

.chart-state i {
  font-size: 48px;
  opacity: 0.4;
}

.chart-state span {
  opacity: 0.7;
}
</style>
