import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";

import {
  chartRows,
  useStatsCsv,
  useStatsCsvReady,
  type StatsChart,
} from "./useStatsCsv";

const downloadJs = vi.hoisted(() => vi.fn());

vi.mock("downloadjs", () => ({ default: downloadJs }));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const BOM_BYTES = [0xef, 0xbb, 0xbf];

const bars = [
  { label: "Aurora", count: 3, tooltip: "Aurora: 3 Ships" },
  { label: "Drake, Interplanetary", count: 1, tooltip: "..." },
];

const slices = [
  { name: "large", y: 2, selected: false, sliced: false },
  { name: "small", y: 1, selected: false, sliced: false },
];

const lastDownload = () => {
  const [blob, filename] = downloadJs.mock.calls.at(-1) as [Blob, string];

  return { blob, filename };
};

const lastBytes = async () =>
  new Uint8Array(await lastDownload().blob.arrayBuffer());

// Byte-level and past the BOM, because `Blob.text()` performs a UTF-8 decode
// and that strips a leading BOM - the very thing the export writes for Excel.
const lastCsv = async () =>
  new TextDecoder().decode((await lastBytes()).slice(BOM_BYTES.length));

beforeEach(() => {
  downloadJs.mockClear();
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-09-02T10:00:00Z"));
});

afterEach(() => {
  vi.useRealTimers();
});

describe("chartRows", () => {
  it("reads a label and a count off either point shape", () => {
    expect(chartRows(bars)).toEqual([
      ["Aurora", 3],
      ["Drake, Interplanetary", 1],
    ]);
    expect(chartRows(slices)).toEqual([
      ["large", 2],
      ["small", 1],
    ]);
  });

  it("is empty for a chart whose data has not landed", () => {
    expect(chartRows(undefined)).toEqual([]);
    expect(chartRows(null)).toEqual([]);
  });
});

describe("useStatsCsv", () => {
  describe("exportChart", () => {
    it("writes one two-column section headed by the chart's title", async () => {
      useStatsCsv("stats").exportChart({
        name: "models-by-size",
        title: "Ships by Size",
        points: slices,
      });

      expect(await lastCsv()).toBe(
        "Ships by Size,labels.stats.csv.count\r\nlarge,2\r\nsmall,1",
      );
    });

    it("opens the file with a UTF-8 BOM, so Excel reads it as UTF-8", async () => {
      useStatsCsv("stats").exportChart({
        name: "models-by-size",
        title: "Ships by Size",
        points: slices,
      });

      const { blob } = lastDownload();

      expect(Array.from((await lastBytes()).slice(0, 3))).toEqual(BOM_BYTES);
      expect(blob.type).toBe("text/csv;charset=utf-8");
    });

    it("names the file after the scope, the chart and the day", () => {
      useStatsCsv("stats").exportChart({
        name: "models-by-size",
        title: "Ships by Size",
        points: slices,
      });

      expect(lastDownload().filename).toBe(
        "fleetyards-stats-models-by-size-2026-09-02.csv",
      );
    });

    it("tracks a reactive scope", () => {
      const scope = ref("aurora-hangar");
      const { exportChart } = useStatsCsv(scope);

      scope.value = "reaper-fleet";

      exportChart({ name: "models-by-size", title: "t", points: slices });

      expect(lastDownload().filename).toBe(
        "fleetyards-reaper-fleet-models-by-size-2026-09-02.csv",
      );
    });

    it("quotes a label carrying a delimiter", async () => {
      useStatsCsv("stats").exportChart({
        name: "models-by-manufacturer",
        title: "Ships by Manufacturer",
        points: bars,
      });

      expect(await lastCsv()).toContain('"Drake, Interplanetary",1');
    });

    it("downloads nothing for a chart with no data", () => {
      useStatsCsv("stats").exportChart({
        name: "models-by-size",
        title: "Ships by Size",
        points: [],
      });

      expect(downloadJs).not.toHaveBeenCalled();
    });
  });

  describe("exportAll", () => {
    const charts: StatsChart[] = [
      { name: "models-by-size", title: "Ships by Size", points: slices },
      { name: "models-per-month", title: "Ships per Month", points: [] },
      { name: "vehicles-by-model", title: "Ships by Model", points: bars },
    ];

    it("leads with the metrics, then one section per chart that has data", async () => {
      useStatsCsv("hangar").exportAll(
        [
          { label: "Total Ships", value: 4 },
          { label: "Average Price", value: 72.5 },
        ],
        charts,
      );

      expect(await lastCsv()).toBe(
        [
          "labels.stats.csv.metric,labels.stats.csv.value",
          "Total Ships,4",
          "Average Price,72.5",
          "",
          "Ships by Size,labels.stats.csv.count",
          "large,2",
          "small,1",
          "",
          "Ships by Model,labels.stats.csv.count",
          "Aurora,3",
          '"Drake, Interplanetary",1',
        ].join("\r\n"),
      );
    });

    it("skips a metric whose query has not answered yet", async () => {
      useStatsCsv("hangar").exportAll(
        [
          { label: "Total Ships", value: 4 },
          { label: "Total Credits", value: undefined },
          { label: "Total Cargo", value: null },
          { label: "Flight Ready", value: 0 },
        ],
        [],
      );

      expect(await lastCsv()).toBe(
        [
          "labels.stats.csv.metric,labels.stats.csv.value",
          "Total Ships,4",
          "Flight Ready,0",
        ].join("\r\n"),
      );
    });

    it("names the file after the scope and the day only", () => {
      useStatsCsv("aurora-hangar").exportAll([], charts);

      expect(lastDownload().filename).toBe(
        "fleetyards-aurora-hangar-2026-09-02.csv",
      );
    });

    it("downloads nothing when neither the metrics nor the charts have data", () => {
      useStatsCsv("hangar").exportAll(
        [{ label: "Total Ships", value: undefined }],
        [{ name: "models-by-size", title: "t", points: [] }],
      );

      expect(downloadJs).not.toHaveBeenCalled();
    });
  });
});

describe("useStatsCsvReady", () => {
  it("is false while every chart and metric is still empty", () => {
    const ready = useStatsCsvReady(
      () => [{ name: "a", title: "a", points: [] }],
      () => [{ label: "Total Ships", value: null }],
    );

    expect(ready.value).toBe(false);
  });

  it("is true once one chart has a point", () => {
    const charts = ref<StatsChart[]>([{ name: "a", title: "a", points: [] }]);
    const ready = useStatsCsvReady(charts);

    expect(ready.value).toBe(false);

    charts.value = [{ name: "a", title: "a", points: slices }];

    expect(ready.value).toBe(true);
  });

  it("is true once one metric has a value, charts or not", () => {
    const ready = useStatsCsvReady(
      () => [],
      () => [{ label: "Total Ships", value: 0 }],
    );

    expect(ready.value).toBe(true);
  });
});
