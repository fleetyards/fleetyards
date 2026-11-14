<script lang="ts">
export default {
  name: "SupporterContributionsDailyChart",
};
</script>

<script lang="ts" setup>
import Highcharts from "highcharts";
import "highcharts/esm/modules/accessibility";
import { useChartTheme } from "@/shared/composables/useChartTheme";
import {
  useSupporterContributionsPerDay,
  type SupporterContributionsPerDayParams,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import type { MaybeRef } from "vue";

type Props = {
  params?: MaybeRef<SupporterContributionsPerDayParams>;
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
  () => unref(props.params) as SupporterContributionsPerDayParams,
);

const { data: perDay } = useSupporterContributionsPerDay(queryParams);

const items = computed(() => perDay.value?.items ?? []);

const currency = computed(() => perDay.value?.currency ?? "EUR");

const goalAmountCents = computed(() => perDay.value?.goalAmountCents ?? 0);

const container = ref<HTMLElement | undefined>();

const instance = ref<Highcharts.Chart | undefined>();

const toMajor = (amountCents: number) => amountCents / 100;

const formatMajor = (value: number) => formatCents(value * 100, currency.value);

const tooltipFormatter = function (this: Highcharts.Point) {
  const day = Number(this.x);

  const lines = items.value.flatMap((item) => {
    const amountCents = item.days[day - 1];

    if (amountCents === undefined) {
      return [];
    }

    return [
      t("chart.labels.supporterContribution.month", {
        label: item.label,
        amount: formatCents(amountCents, currency.value),
      }),
    ];
  });

  return [
    `<b>${t("chart.labels.supporterContribution.day", { day })}</b>`,
    ...lines,
  ].join("<br>");
};

// The current month takes the accent and the heavier stroke; the months before
// it only give it something to be measured against.
const seriesColor = (index: number, current: boolean) => {
  const colors = theme.value.colors ?? [];

  return current ? colors[0] : colors[(index % (colors.length - 1)) + 1];
};

const chartOptions = computed((): Highcharts.Options => {
  const themeYAxis = theme.value.yAxis as Highcharts.YAxisOptions;
  const goal = toMajor(goalAmountCents.value);
  const mutedColor = themeYAxis.title?.style?.color as string | undefined;

  return {
    ...theme.value,
    chart: {
      ...theme.value.chart,
      height: props.height,
    },
    xAxis: {
      ...(theme.value.xAxis as Highcharts.XAxisOptions),
      min: 1,
      max: 31,
      allowDecimals: false,
      tickInterval: 7,
    },
    yAxis: {
      ...themeYAxis,
      min: 0,
      softMax: goal || undefined,
      title: { text: undefined },
      labels: {
        ...themeYAxis.labels,
        formatter() {
          return formatMajor(Number(this.value));
        },
      },
      plotLines: goal
        ? [
            {
              value: goal,
              color: mutedColor,
              dashStyle: "Dash",
              width: 1,
              zIndex: 3,
              label: {
                text: t("labels.supporterContribution.chart.goal"),
                align: "right",
                style: { color: mutedColor },
              },
            },
          ]
        : [],
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
    series: items.value.map((item, index) => ({
      type: "line",
      name: item.label,
      data: item.days.map(toMajor),
      pointStart: 1,
      color: seriesColor(index, item.current),
      lineWidth: item.current ? 3 : 1.5,
      zIndex: item.current ? 2 : 1,
      marker: { enabled: false },
    })),
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

watch(chartOptions, (options) => {
  if (instance.value) {
    instance.value.update(options, true, true);
  } else {
    render();
  }
});
</script>

<template>
  <div
    ref="container"
    class="supporter-contributions-daily-chart"
    data-test="supporter-contributions-daily-chart"
  />
</template>

<style lang="scss" scoped>
.supporter-contributions-daily-chart {
  margin-bottom: 12px;
}
</style>
