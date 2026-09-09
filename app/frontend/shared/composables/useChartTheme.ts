import type { Options } from "highcharts";
import defaultTheme from "@/shared/components/Chart/defaultTheme";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";

/*
 * The accent the document's theme is running, or nothing if it is not readable
 * -- server-side rendering, or a bundle that registers no tokens.
 *
 * Highcharts writes a series colour into an SVG `fill` attribute, and a `var()`
 * in a presentation attribute never resolves, so a chart cannot pick up the
 * theme the way every other component does. It is the same shape as the
 * animation problem below: the value has to be looked up in JS and handed over.
 *
 * Read off `documentElement`, because that is where the theme attribute sits. A
 * chart inside an element that scopes its own theme therefore still draws in the
 * document's accent -- worth knowing when previewing a theme in-page.
 */
const documentAccent = (): string | undefined => {
  if (typeof document === "undefined") {
    return undefined;
  }

  return (
    getComputedStyle(document.documentElement)
      .getPropertyValue("--color-primary")
      .trim() || undefined
  );
};

// Highcharts animates from JS, so the `prefers-reduced-motion` media queries the
// rest of the app styles with never reach it — the theme has to opt out itself.
export const useChartTheme = () => {
  const { prefersReducedMotion } = useReducedMotion();

  const animation = computed(() => !prefersReducedMotion.value);

  /*
   * Only the first colour is themed. It is the one a single-series chart draws
   * in, which is every chart the app builds today; the rest of the array are
   * accompanying series colours that carry no brand meaning and would lose their
   * distinguishability if they all shifted with the accent.
   */
  const colors = computed(() => {
    const accent = documentAccent();
    const palette = defaultTheme.colors ?? [];

    if (!accent) {
      return palette;
    }

    return [accent, ...palette.slice(1)];
  });

  const theme = computed((): Options => ({
    ...defaultTheme,
    colors: colors.value,
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
