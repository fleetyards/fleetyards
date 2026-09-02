import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { format } from "date-fns";
import downloadJs from "downloadjs";
import { sectionsToCsv, type CsvSection } from "@/shared/utils/Csv";
import { useI18n } from "@/shared/composables/useI18n";
import type { PieChartStats, BarChartStats } from "@/services/fyApi";

/*
 * Both shapes the API serves a chart in, plus the bare Highcharts point the
 * fleet's members-by-role chart is assembled from in the component. They differ
 * only in what the label and the value are called.
 */
export type StatsChartPoint =
  PieChartStats | BarChartStats | { name: string; y: number };

export type StatsChart = {
  /** Slug for the per-chart filename; the same `name` the Chart component gets. */
  name: string;
  /** The panel heading, which is also this section's first header cell. */
  title: string;
  points?: StatsChartPoint[] | null;
};

export type StatsMetric = {
  label: string;
  value: number | string | null | undefined;
};

// Excel reads a file without one as the system codepage, which mojibakes every
// non-ASCII manufacturer, ship and fleet-role name and empties the CJK headers.
const BOM = "\uFEFF";

const pointLabel = (point: StatsChartPoint): string =>
  "label" in point ? point.label : point.name;

const pointValue = (point: StatsChartPoint): number =>
  "count" in point ? point.count : point.y;

export const chartRows = (points?: StatsChartPoint[] | null) =>
  (points || []).map((point) => [pointLabel(point), pointValue(point)]);

const hasValue = ({ value }: StatsMetric) =>
  value !== null && value !== undefined;

/**
 * Builds the CSV a stats page hands to the browser, from data the page has
 * already fetched. `scope` names the subject - "stats", "hangar",
 * "<username>-hangar", "<slug>-fleet" - and lands in the filename.
 */
export const useStatsCsv = (scope: MaybeRefOrGetter<string>) => {
  const { t } = useI18n();

  const filename = (suffix?: string) =>
    `${["fleetyards", toValue(scope), suffix, format(new Date(), "yyyy-MM-dd")]
      .filter(Boolean)
      .join("-")}.csv`;

  const chartSection = (chart: StatsChart): CsvSection => ({
    headers: [chart.title, t("labels.stats.csv.count")],
    rows: chartRows(chart.points),
  });

  const metricsSection = (metrics: StatsMetric[]): CsvSection => ({
    headers: [t("labels.stats.csv.metric"), t("labels.stats.csv.value")],
    rows: metrics.filter(hasValue).map(({ label, value }) => [label, value]),
  });

  const download = (name: string, sections: CsvSection[]) => {
    const csv = sectionsToCsv(sections);

    if (!csv) {
      return;
    }

    downloadJs(
      new Blob([BOM + csv], { type: "text/csv;charset=utf-8" }),
      name,
      "text/csv",
    );
  };

  const exportChart = (chart: StatsChart) =>
    download(filename(chart.name), [chartSection(chart)]);

  const exportAll = (metrics: StatsMetric[], charts: StatsChart[]) =>
    download(filename(), [
      metricsSection(metrics),
      ...charts.map(chartSection),
    ]);

  return { filename, chartSection, metricsSection, exportChart, exportAll };
};

/**
 * True once there is something to write. The export controls stay disabled until
 * then, so a click while the queries are still in flight cannot hand the user an
 * empty file.
 */
export const useStatsCsvReady = (
  charts: MaybeRefOrGetter<StatsChart[]>,
  metrics: MaybeRefOrGetter<StatsMetric[]> = () => [],
) =>
  computed(
    () =>
      toValue(charts).some((chart) => !!chart.points?.length) ||
      toValue(metrics).some(hasValue),
  );
