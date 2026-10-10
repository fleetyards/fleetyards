import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import Component from "./index.vue";

const mount = async (props: Record<string, boolean>) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { title: "Panel", ...props },
    slots: {
      default: () => [h("p", { class: "content" }, "content")],
      empty: () => [h("p", { class: "empty" }, "empty")],
    },
  });

describe("FleetDashboardPanel", () => {
  it("says nothing yet while the first answer is out", async () => {
    const subject = await mount({ pending: true, empty: true });

    expect(subject.find(".empty").exists()).toBe(false);
    expect(subject.find("[data-test='fleet-dashboard-failed']").exists()).toBe(
      false,
    );
    expect(subject.find(".panel--loading").exists()).toBe(true);
  });

  it("says it failed rather than that it has nothing", async () => {
    const subject = await mount({ failed: true, empty: true });

    expect(subject.find("[data-test='fleet-dashboard-failed']").exists()).toBe(
      true,
    );
    expect(subject.find(".empty").exists()).toBe(false);
  });

  it("shows its empty state once answered empty", async () => {
    const subject = await mount({ empty: true });

    expect(subject.find(".empty").exists()).toBe(true);
  });

  it("keeps what it says under a refetch", async () => {
    const subject = await mount({ fetching: true });

    expect(subject.find(".content").exists()).toBe(true);
    expect(subject.find(".panel--loading").exists()).toBe(true);
  });
});
