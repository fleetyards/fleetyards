import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import type { Component } from "@/services/fyApi";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useBlueprints: () => ({ data: ref({ items: [] }), isPending: ref(false) }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    tExists: () => false,
    toNumber: (value: number) => String(value),
  }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

import ComponentPage from "./index.vue";

const record = (overrides: Partial<Component> = {}): Component =>
  ({
    id: "c0000000-0000-0000-0000-000000000001",
    name: "Hull Plate",
    slug: "hull-plate",
    category: "not_a_category",
    hidden: false,
    retired: false,
    catalogued: true,
    availability: { boughtAt: [], soldAt: [] },
    media: {},
    createdAt: "2026-09-01T00:00:00Z",
    updatedAt: "2026-09-02T00:00:00Z",
    ...overrides,
  }) as Component;

const mountPage = async (component: Component) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "components", component: { template: "<div />" } },
      {
        path: "/components/:slug/history/",
        name: "component-history",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push("/");
  await router.isReady();

  return mount(ComponentPage, {
    props: { component },
    global: {
      plugins: [router],
      stubs: {
        BreadCrumbs: true,
        Availability: true,
        Chip: true,
        MetricsCard: {
          props: ["title"],
          template: "<section :data-title='title'><slot /></section>",
        },
      },
    },
  });
};

const titles = (wrapper: Awaited<ReturnType<typeof mountPage>>) =>
  wrapper.findAll("section").map((section) => section.attributes("data-title"));

describe("ComponentPage", () => {
  it("says so when a component has no figures at all", async () => {
    const wrapper = await mountPage(record());

    expect(wrapper.text()).toContain("labels.component.noMetrics");
  });

  it("leaves the metrics card out when durability is all there is", async () => {
    const wrapper = await mountPage(record({ durability: { health: 100 } }));

    expect(wrapper.text()).not.toContain("labels.component.noMetrics");
    expect(titles(wrapper)).toContain("headlines.component.physical");
    expect(titles(wrapper)).not.toContain("headlines.component.metrics");
  });

  it("gives a quantum drive's spline jump a card of its own", async () => {
    const wrapper = await mountPage(
      record({
        category: "quantumdrive",
        typeData: {
          driveSpeed: 263_400_000,
          splineJumpParams: { driveSpeed: 400_000, spoolUpTime: 6 },
        },
      } as Partial<Component>),
    );

    expect(titles(wrapper)).toContain("headlines.component.splineJump");

    const metrics = wrapper
      .findAll("section")
      .find(
        (section) =>
          section.attributes("data-title") === "headlines.component.metrics",
      );
    expect(metrics?.text()).not.toContain(
      "labels.hardpoint.quantumDrives.splineSpeed",
    );
  });
});
