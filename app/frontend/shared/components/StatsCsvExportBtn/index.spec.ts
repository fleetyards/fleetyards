import { describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";

import Component from "./index.vue";
import {
  type StatsChart,
  type StatsMetric,
} from "@/shared/composables/useStatsCsv";

const downloadJs = vi.hoisted(() => vi.fn());

vi.mock("downloadjs", () => ({ default: downloadJs }));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const slices = [
  { name: "large", y: 2, selected: false, sliced: false },
  { name: "small", y: 1, selected: false, sliced: false },
];

const bySize: StatsChart = {
  name: "models-by-size",
  title: "Ships by Size",
  points: slices,
};

const mountWith = (props: {
  chart?: StatsChart;
  charts?: StatsChart[];
  metrics?: StatsMetric[];
  withLabel?: boolean;
}) =>
  mount(Component, {
    props: { scope: "stats", ...props },
    global: {
      stubs: {
        Btn: {
          inheritAttrs: false,
          props: ["disabled"],
          template:
            '<button v-bind="$attrs" :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
        },
      },
      directives: { tooltip: () => {} },
    },
  });

describe("StatsCsvExportBtn", () => {
  it("names itself after the chart it exports", () => {
    const wrapper = mountWith({ chart: bySize });

    expect(
      wrapper.find('[data-test="export-csv-models-by-size"]').exists(),
    ).toBe(true);
  });

  it("is the page-level button when handed a list instead of one chart", () => {
    const wrapper = mountWith({ charts: [bySize] });

    expect(wrapper.find('[data-test="export-csv-all"]').exists()).toBe(true);
  });

  it("carries an icon and no label unless asked for one", () => {
    expect(mountWith({ chart: bySize }).text()).toBe("");
    expect(mountWith({ chart: bySize, withLabel: true }).text()).toBe(
      "actions.exportCsv",
    );
  });

  it("stays disabled while the chart has no data", () => {
    const wrapper = mountWith({
      chart: { name: "models-by-size", title: "Ships by Size", points: [] },
    });

    expect(wrapper.get<HTMLButtonElement>("button").element.disabled).toBe(
      true,
    );
  });

  it("enables once the data lands", () => {
    const wrapper = mountWith({ chart: bySize });

    expect(wrapper.get<HTMLButtonElement>("button").element.disabled).toBe(
      false,
    );
  });

  it("exports just its own chart on click", async () => {
    downloadJs.mockClear();

    await mountWith({ chart: bySize }).get("button").trigger("click");

    const [, filename] = downloadJs.mock.calls.at(-1) as [Blob, string];

    expect(filename).toContain("fleetyards-stats-models-by-size-");
  });

  it("exports the whole page on click, without a chart name in the file", async () => {
    downloadJs.mockClear();

    await mountWith({
      charts: [bySize],
      metrics: [{ label: "Total Ships", value: 3 }],
    })
      .get("button")
      .trigger("click");

    const [, filename] = downloadJs.mock.calls.at(-1) as [Blob, string];

    expect(filename).toContain("fleetyards-stats-");
    expect(filename).not.toContain("models-by-size");
  });

  it("is enabled by metrics alone, for a page whose charts are all empty", () => {
    const wrapper = mountWith({
      charts: [{ name: "models-by-size", title: "t", points: [] }],
      metrics: [{ label: "Total Ships", value: 3 }],
    });

    expect(wrapper.get<HTMLButtonElement>("button").element.disabled).toBe(
      false,
    );
  });
});
