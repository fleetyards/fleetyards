<script lang="ts">
export default {
  name: "SupporterContributionsMonthlyChart",
};
</script>

<script lang="ts" setup>
import Highcharts from "highcharts";
import "highcharts/modules/accessibility";
import { useChartTheme } from "@/shared/composables/useChartTheme";
import {
  useSupporterContributionsPerMonth,
  type SupporterContributionsPerMonthParams,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import type { MaybeRef } from "vue";

type Props = {
  params?: MaybeRef<SupporterContributionsPerMonthParams>;
  height?: number;
};

const props = withDefaults(defineProps<Props>(), {
  params: undefined,
  height: 260,
});

const { t } = useI18n();
const { theme } = useChartTheme();
const { formatCents } = useCurrencyFormat();

const queryParams = computed(
  () => unref(props.params) as SupporterContributionsPerMonthParams,
);

const { data: perMonth } = useSupporterContributionsPerMonth(queryParams);

const items = computed(() => perMonth.value?.items ?? []);

const currency = computed(() => perMonth.value?.currency ?? "EUR");

const container = ref<HTMLElement | undefined>();

const instance = ref<Highcharts.Chart | undefined>();

// The API is authoritative in cents; Highcharts plots major units so the axis
// ticks and the goal line sit on a scale that reads as money.
const toMajor = (amountCents: number) => amountCents / 100;

const formatMajor = (value: number) => formatCents(value * 100, currency.value);

// Both series share a category index, so the hovered point identifies the month
// regardless of which of the two the cursor landed on.
const tooltipFormatter = function (this: Highcharts.Point) {
  const item = items.value[this.index];

  if (!item) {
    return "";
  }

  return [
    `<b>${item.tooltip}</b>`,
    t("chart.labels.supporterContribution.amount", {
      amount: formatCents(item.amountCents, currency.value),
    }),
    t("chart.labels.supporterContribution.goal", {
      amount: formatCents(item.goalAmountCents, currency.value),
    }),
    t("chart.labels.supporterContribution.count", { count: item.count }),
  ].join("<br>");
};

const chartOptions = computed((): Highcharts.Options => {
  const themeYAxis = theme.value.yAxis as Highcharts.YAxisOptions;

  return {
    ...theme.value,
    chart: {
      ...theme.value.chart,
      height: props.height,
    },
    xAxis: {
      ...(theme.value.xAxis as Highcharts.XAxisOptions),
      categories: items.value.map((item) => item.label),
    },
    yAxis: {
      ...themeYAxis,
      min: 0,
      title: { text: undefined },
      labels: {
        ...themeYAxis.labels,
        formatter() {
          return formatMajor(Number(this.value));
        },
      },
    },
    legend: {
      ...theme.value.legend,
      enabled: true,
    },
    tooltip: {
      ...theme.value.tooltip,
      shared: true,
      formatter: tooltipFormatter,
    },
    series: [
      {
        type: "column",
        name: t("labels.supporterContribution.chart.contributions"),
        data: items.value.map((item) => toMajor(item.amountCents)),
      },
      {
        type: "spline",
        name: t("labels.supporterContribution.chart.goal"),
        data: items.value.map((item) => toMajor(item.goalAmountCents)),
        marker: { enabled: false },
      },
    ],
  };
});

const render = () => {
  if (!container.value) {
    return;
  }

  instance.value = Highcharts.chart(container.value, chartOptions.value);
};

onMounted(render);

onBeforeUnmount(() => {
  instance.value?.destroy();
  instance.value = undefined;
});

watch(
  () => chartOptions.value,
  (options) => {
    if (instance.value) {
      instance.value.update(options, true, true);
    } else {
      render();
    }
  },
  { deep: true },
);
</script>

<template>
  <div
    ref="container"
    class="supporter-contributions-monthly-chart"
    data-test="supporter-contributions-monthly-chart"
  />
</template>

<style lang="scss" scoped>
.supporter-contributions-monthly-chart {
  margin-bottom: 12px;
}
</style>
