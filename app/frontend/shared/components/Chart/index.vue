<template>
  <div
    :id="uuid"
    :class="{
      loading,
    }"
    class="chart"
  />
</template>

<script lang="ts" setup>
import { chart } from "highcharts";
import type { TooltipFormatterContextObject } from "highcharts";
import type { PieChartStats, BarChartStats } from "@/services/fyApi";
import { v4 as uuidv4 } from "uuid";
import defaultTheme from "./defaultTheme";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import { useQuery } from "@tanstack/vue-query";

type TooltipLabelOption = {
  label: number;
  count: number;
  percentage?: number;
};

type ChartData = PieChartStats | BarChartStats;

type Props = {
  name: string;
  loadData: () => Promise<ChartData[]>;
  type?: "line" | "bar" | "column" | "area" | "pie";
  reload?: number;
  tooltipType?: string;
  height?: number;
};

const props = withDefaults(defineProps<Props>(), {
  type: "line",
  tooltipType: "",
  reload: undefined,
  height: 400,
});

const i18n = inject<I18nPluginOptions>("i18n");

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
      categories: (data.value as BarChartStats[]).map((item) => item.label),
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
    return undefined;
  }

  return theme.value.legend;
});

const chartData = computed(() => {
  if (chartWithCategory.value) {
    return (data.value as BarChartStats[]).map((item) => [
      item.tooltip,
      item.count,
    ]);
  }

  return data.value;
});

onMounted(() => {
  uuid.value = `chart-${uuidv4()}`;

  setupChart();

  if (props.reload) {
    interval.value = setInterval(() => {
      refetch();
      // reloadChart();
    }, props.reload * 1000);
  }
});

const tooltipFormat = (tooltip: TooltipFormatterContextObject) => {
  const options: TooltipLabelOption = {
    label: tooltip.key,
    count: tooltip.y,
    percentage: undefined,
  };

  if (props.type === "pie") {
    options.percentage = Math.round(tooltip.percentage || 0);
  }

  return i18n?.t(`labels.charts.${props.tooltipType}`, options);
};

const loading = computed(() => {
  return isLoading.value || isFetching.value;
});

const { isLoading, isFetching, data, refetch } = useQuery({
  queryKey: [props.name],
  queryFn: () => props.loadData(),
});

watch(
  () => data.value,
  () => {
    if (instance.value) {
      reloadChart();
    } else {
      setupChart();
    }
  }
);

const reloadChart = async () => {
  if (!data.value) {
    return;
  }

  const series = instance.value?.series[0];

  if (!series) {
    return;
  }

  if (chartWithCategory.value) {
    series.setData(
      (data.value as BarChartStats[]).map((item) => [item.tooltip, item.count])
    );

    instance.value?.xAxis[0].setCategories(
      (data.value as BarChartStats[]).map((item) => item.label || "")
    );
  } else {
    series.setData(data.value);
  }
};

const setupChart = () => {
  instance.value = chart({
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

<script lang="ts">
export default {
  name: "ChartComponent",
};
</script>
