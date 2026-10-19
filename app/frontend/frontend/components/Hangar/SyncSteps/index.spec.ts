import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { SyncStep } from "./types";
import { h } from "vue";

// jsdom has no matchMedia; a finished step asks it for reduced motion before
// it folds away.
vi.stubGlobal(
  "matchMedia",
  vi.fn(() => ({
    matches: false,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
  })),
);

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

  it("names each step's status for screen readers", async () => {
    const wrapper = await mountSteps([
      { key: "read", label: "Reading", status: "done" },
      { key: "save", label: "Saving", status: "active" },
    ]);

    expect(wrapper.get("[data-test='sync-step-read'] .sr-only").text()).toBe(
      "Done",
    );
    expect(
      wrapper.get("[data-test='sync-step-save']").attributes("aria-current"),
    ).toBe("step");
    expect(
      wrapper.get("[data-test='sync-step-read']").attributes("aria-current"),
    ).toBeUndefined();
  });

  it("folds a step the run has moved on from, and opens it again on request", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        steps: [
          { key: "read", label: "Reading", status: "done", caption: "6 items" },
          { key: "save", label: "Saving", status: "active" },
        ],
      },
      slots: { "step-read": () => [h("ul", [h("li", "Ships")])] },
    });

    const heading = wrapper.get("[data-test='sync-step-read-heading']");

    expect(heading.element.tagName).toBe("BUTTON");
    expect(heading.attributes("aria-expanded")).toBe("false");

    await heading.trigger("click");

    expect(heading.attributes("aria-expanded")).toBe("true");
    expect(
      wrapper.get("[data-test='sync-step-save-heading']").element.tagName,
    ).toBe("DIV");
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
    expect(bar.classes()).toContain("sync-progress-bar--indeterminate");
  });
});
