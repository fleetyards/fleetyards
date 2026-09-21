import type Highcharts from "highcharts";

/**
 * A named line of its own, plotted against shared categories.
 *
 * `Chart`'s `options` prop can only describe one series — label and count —
 * which is all a stats chart needs. A price history is six of them, and they
 * have to share an axis to be read against each other.
 */
export type ChartSeries = {
  name: string;
  // Nullable per point: a day nothing was sampled is a gap in the line, not a
  // zero, and a zero would drag the axis to the floor.
  data: (number | null)[];
  dashStyle?: Highcharts.DashStyleValue;
};
