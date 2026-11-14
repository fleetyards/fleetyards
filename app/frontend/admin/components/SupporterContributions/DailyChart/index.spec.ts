import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type Highcharts from "highcharts";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { SupporterContributionDailyStats } from "@/services/fyAdminApi";
import DailyChart from "./index.vue";

const { chart } = vi.hoisted(() => ({
  chart: vi.fn(() => ({ update: vi.fn(), destroy: vi.fn() })),
}));

vi.mock("highcharts", () => ({ default: { chart } }));
vi.mock("highcharts/esm/modules/accessibility", () => ({}));
vi.mock("@/shared/composables/useReducedMotion", () => ({
  useReducedMotion: () => ({ prefersReducedMotion: ref(false) }),
}));

const days = (count: number, perDay: number) =>
  Array.from({ length: count }, (_, index) => (index + 1) * perDay);

const payload: SupporterContributionDailyStats = {
  currency: "EUR",
  goalAmountCents: 9000,
  items: [
    { label: "May 2026", current: false, days: days(31, 100), projection: [] },
    { label: "June 2026", current: false, days: days(30, 100), projection: [] },
    { label: "July 2026", current: false, days: days(31, 100), projection: [] },
    {
      label: "August 2026",
      current: true,
      days: days(20, 200),
      projection: days(12, 100).map((amount) => amount + 3900),
    },
  ],
};

vi.mock("@/services/fyAdminApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyAdminApi")>()),
  useSupporterContributionsPerDay: () => ({ data: ref(payload) }),
}));

const renderedOptions = async () => {
  chart.mockClear();
  await mountWithDefaults(DailyChart);

  return chart.mock.calls.at(-1)!.at(1) as unknown as Highcharts.Options;
};

describe("SupporterContributionsDailyChart", () => {
  it("draws a line per month in major units, starting on the 1st", async () => {
    const options = await renderedOptions();
    const series = options.series as Highcharts.SeriesLineOptions[];

    const months = series.slice(0, 4);

    expect(months.map((entry) => entry.name)).toEqual([
      "May 2026",
      "June 2026",
      "July 2026",
      "August 2026",
    ]);
    expect(months.every((entry) => entry.pointStart === 1)).toBe(true);
    expect(months.at(-1)!.data!.at(-1)).toBe(40);
  });

  it("sets the current month apart from the months it is measured against", async () => {
    const series = (await renderedOptions())
      .series as Highcharts.SeriesLineOptions[];
    const current = series[3];
    const past = series.slice(0, 3);

    expect(current.lineWidth).toBeGreaterThan(past[0].lineWidth!);
    expect(new Set(series.slice(0, 4).map((entry) => entry.color)).size).toBe(
      4,
    );
  });

  it("continues the current month as a dashed projection from today", async () => {
    const series = (await renderedOptions())
      .series as Highcharts.SeriesLineOptions[];
    const projection = series.at(-1)!;

    expect(series).toHaveLength(5);
    expect(projection.name).toBe("Projection");
    expect(projection.dashStyle).toBe("ShortDash");
    expect(projection.color).toBe(series[3].color);
    expect(projection.pointStart).toBe(20);
    expect(projection.data!.at(0)).toBe(40);
    expect(projection.data!.at(-1)).toBe(51);
  });

  it("marks the funding goal as a reference line", async () => {
    const yAxis = (await renderedOptions()).yAxis as Highcharts.YAxisOptions;

    expect(yAxis.plotLines).toHaveLength(1);
    expect(yAxis.plotLines![0].value).toBe(90);
  });

  it("lists only the months that reach the hovered day", async () => {
    const tooltip = (await renderedOptions())
      .tooltip as Highcharts.TooltipOptions;
    const text = (
      tooltip.formatter as unknown as (this: { x: number }) => string
    ).call({ x: 31 });

    expect(text).toContain("May 2026");
    expect(text).toContain("July 2026");
    expect(text).not.toContain("June 2026");
    expect(text).not.toContain("August 2026");
    expect(text).toContain("Projection");
  });
});
