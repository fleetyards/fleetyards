import type { Options } from "highcharts";
import defaultTheme from "@/shared/components/Chart/defaultTheme";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";

// Highcharts animates from JS, so the `prefers-reduced-motion` media queries the
// rest of the app styles with never reach it — the theme has to opt out itself.
export const useChartTheme = () => {
  const { prefersReducedMotion } = useReducedMotion();

  const animation = computed(() => !prefersReducedMotion.value);

  const theme = computed((): Options => ({
    ...defaultTheme,
    chart: {
      ...defaultTheme.chart,
      animation: animation.value,
    },
    plotOptions: {
      ...defaultTheme.plotOptions,
      series: {
        ...defaultTheme.plotOptions?.series,
        animation: animation.value,
      },
    },
  }));

  return { theme };
};
