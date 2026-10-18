import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { SyncStep } from "./types";

const mountSteps = (steps: SyncStep[]) =>
  mountWithDefaults<typeof Component>(Component, { props: { steps } });

describe("HangarSyncSteps", () => {
  it("marks each step by its status", async () => {
    const wrapper = await mountSteps([
      { key: "read", label: "Reading", status: "done" },
      { key: "save", label: "Saving", status: "failed" },
      { key: "prices", label: "Prices", status: "pending" },
    ]);

    expect(
      wrapper.find("[data-test='sync-step-read'] .fa-check").exists(),
    ).toBe(true);
    expect(
      wrapper.find("[data-test='sync-step-save'] .fa-xmark").exists(),
    ).toBe(true);
    expect(
      wrapper.get("[data-test='sync-step-prices'] .sync-steps__marker").text(),
    ).toBe("3");
  });

  it("reports a fraction where the step knows its total", async () => {
    const wrapper = await mountSteps([
      {
        key: "prices",
        label: "Prices",
        status: "active",
        progress: { value: 12, max: 37 },
      },
    ]);

    const bar = wrapper.get("[role='progressbar']");

    expect(bar.attributes("aria-valuenow")).toBe("12");
    expect(bar.attributes("aria-valuemax")).toBe("37");
  });

  // An indeterminate progressbar has no value at all, rather than a made-up one.
  it("leaves the value out where there is no total", async () => {
    const wrapper = await mountSteps([
      {
        key: "read",
        label: "Reading",
        status: "active",
        progress: "indeterminate",
      },
    ]);

    const bar = wrapper.get("[role='progressbar']");

    expect(bar.attributes("aria-valuenow")).toBeUndefined();
    expect(bar.classes()).toContain("sync-steps__bar--indeterminate");
  });
});
