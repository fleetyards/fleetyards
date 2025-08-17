<script lang="ts">
export default {
  name: "ChartComponent",
};
</script>

<script lang="ts" setup>
import Highcharts from "highcharts";
import "highcharts/modules/accessibility";
import type { PieChartStats, BarChartStats } from "@/services/fyApi";
import { v4 as uuidv4 } from "uuid";
import defaultTheme from "./defaultTheme";
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
};

const props = withDefaults(defineProps<Props>(), {
  options: () => [],
  type: "line",
  tooltipType: "",
  reload: undefined,
  height: 400,
});

const { t } = useI18n();

const chart = ref<HTMLElement | undefined>();

const uuid = ref(`chart-${uuidv4()}`);

const instance = ref<Highcharts.Chart | undefined>();

const interval = ref<NodeJS.Timeout | undefined>();

const theme = ref<Highcharts.Options>(defaultTheme);

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

const tooltipFormat = (tooltip: Highcharts.TooltipFormatterContextObject) => {
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

const loading = computed(() => {
  return (
    props.asyncStatus.isLoading.value || props.asyncStatus.isFetching.value
  );
});

watch(
  () => props.options,
  async () => {
    if (instance.value) {
      await reloadChart();
    } else {
      setupChart();
    }
  },
  {
    deep: true,
  },
);

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
  if (!chart.value) {
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
  <div
    :id="uuid"
    ref="chart"
    :class="{
      loading,
    }"
    class="chart"
  />
</template>
