import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import type { Component } from "@/services/fyApi";

const craftedRecipe = vi.hoisted(() => ({ value: undefined as unknown }));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useBlueprints: () => ({ data: ref({ items: [] }), isPending: ref(false) }),
  // The recipe a crafted part's address names; none of these do.
  useBlueprint: () => ({
    data: ref(craftedRecipe.value),
    isPlaceholderData: ref(false),
  }),
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

const mountPage = async (component: Component, path = "/") => {
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
  await router.push(path);
  await router.isReady();

  return mount(ComponentPage, {
    props: { component },
    global: {
      plugins: [router],
      stubs: {
        BreadCrumbs: true,
        ExternalLinks: true,
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
    expect(titles(wrapper)).toContain("headlines.component.durability");
    expect(
      wrapper
        .find("[data-title='headlines.component.durability']")
        .find("[data-test='durability-physical']")
        .exists(),
    ).toBe(true);
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

  // A crafted part's card links here with its recipe and grades in the
  // address, and the page shows the part as they left it.
  it("shows a crafted part's figures when the address names its recipe", async () => {
    craftedRecipe.value = {
      name: "Hull Plate Blueprint",
      slug: "hull-plate-bp",
      craftable: { id: "c0000000-0000-0000-0000-000000000001" },
      costSlots: [
        {
          position: 1,
          modifiers: [
            {
              propertyKey: "gpp_health_maxhealth",
              startQuality: 0,
              endQuality: 1000,
              modifierAtStart: 0.8,
              modifierAtEnd: 1.2,
            },
          ],
        },
      ],
    };

    const wrapper = await mountPage(
      record({ durability: { health: 100 } }),
      "/?crafted=hull-plate-bp&grades=1:1000",
    );

    expect(wrapper.find("[data-test='component-crafted']").exists()).toBe(true);
    expect(wrapper.text()).toContain("120");

    craftedRecipe.value = undefined;
  });
});
