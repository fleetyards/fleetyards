import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import type { Component, ComponentBuildChange } from "@/services/fyApi";

const changes = vi.hoisted(() => ({
  value: [] as ComponentBuildChange[],
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useComponentChanges: () => ({ data: toRef(changes, "value") }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    tExists: (key: string) => key.startsWith("labels.component.durability"),
    l: (value: string) => value,
    toNumber: (value: number) =>
      value === 0 ? "labels.notAvailable" : String(value),
  }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

import HistoryPage from "./history.vue";

const change = (
  field: string,
  oldValue: string | null,
  newValue: string | null,
): ComponentBuildChange => ({
  id: field,
  environment: "live",
  fromVersion: "4.10.0",
  toVersion: "4.10.1",
  field,
  metric: false,
  oldValue,
  newValue,
  recordedAt: "2026-09-30T00:00:00Z",
});

const mountPage = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/components/:slug/history/",
        name: "component-history",
        component: { template: "<div />" },
      },
      {
        path: "/components/",
        name: "components",
        component: { template: "<div />" },
      },
      {
        path: "/components/:slug/",
        name: "component",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push("/components/torrent/history/");
  await router.isReady();

  return mount(HistoryPage, {
    props: {
      component: {
        name: "Torrent",
        slug: "torrent",
        category: "quantumdrive",
      } as Component,
    },
    global: {
      plugins: [router],
      stubs: { BreadCrumbs: true },
    },
  });
};

const rows = (wrapper: Awaited<ReturnType<typeof mountPage>>) =>
  wrapper
    .findAll("[data-test='component-changes'] li")
    .map((row) =>
      [
        row.find(".component-history__field").text(),
        row.find(".component-history__values").text().replace(/\s+/g, " "),
      ].join(": "),
    );

describe("ComponentHistoryPage", () => {
  it("labels each durability figure and reads it the way the page does", async () => {
    changes.value = [
      change("durability.mass", "630.0", "700.0"),
      change("durability.resistances.thermal", "0.1", "0.2"),
      change("durability.self_repair.time", null, "56.0"),
      change("durability.distortion.decay_rate", "2.0", "0.0"),
    ];

    expect(rows(await mountPage())).toEqual([
      "labels.component.durabilityChanges.mass: 630 → 700",
      "labels.component.durabilityChanges.resistancesThermal: 10% → 20%",
      "labels.component.durabilityChanges.selfRepairTime: — → 56",
      "labels.component.durabilityChanges.distortionDecayRate: 2 → 0",
    ]);
  });
});
