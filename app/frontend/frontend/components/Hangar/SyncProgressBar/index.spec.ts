import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { SyncProgress } from "./types";

const mountBar = (progress?: SyncProgress) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { progress, label: "Ships", valueText: "2 more than the last sync" },
  });

describe("HangarSyncProgressBar", () => {
  it("shows a value past its reference beyond a mark", async () => {
    const wrapper = await mountBar({
      value: 12,
      max: 10,
      reference: 10,
      final: true,
    });

    const bar = wrapper.get("[role='progressbar']");

    expect(bar.attributes("aria-valuemax")).toBe("12");
    expect(bar.attributes("aria-valuenow")).toBe("12");
    expect(bar.attributes("aria-valuetext")).toBe("2 more than the last sync");
    expect(bar.find(".sync-progress-bar__excess").exists()).toBe(true);
    expect(bar.find(".sync-progress-bar__mark").exists()).toBe(true);
    expect(bar.find(".sync-progress-bar__gap").exists()).toBe(false);
  });

  it("shows the gap only once a value short of its reference is final", async () => {
    const reading = await mountBar({ value: 6, max: 10, reference: 10 });
    expect(reading.find(".sync-progress-bar__gap").exists()).toBe(false);

    const read = await mountBar({
      value: 6,
      max: 10,
      reference: 10,
      final: true,
    });
    expect(read.find(".sync-progress-bar__gap").exists()).toBe(true);
  });

  it("only shows that it is working without a value", async () => {
    const wrapper = await mountBar();

    const bar = wrapper.get("[role='progressbar']");

    expect(bar.classes()).toContain("sync-progress-bar--indeterminate");
    expect(bar.attributes("aria-valuenow")).toBeUndefined();
  });
});
