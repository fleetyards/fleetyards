import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { ScDataPatchSummary } from "@/services/fyApi";
import Component from "./index.vue";

const summary = ref<ScDataPatchSummary | undefined>();
const screens = ref<{ url: string; largeUrl: string }[]>([]);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useScDataPatchSummary: () => ({ data: summary, isLoading: ref(false) }),
  useScDataBuilds: () => ({
    data: ref({
      items: [
        {
          environment: "live",
          version: "4.10.2-live.2",
          default: true,
          loadingScreens: screens.value,
        },
      ],
    }),
  }),
}));

const page = defineComponent({ render: () => null });

// Every page the section links to.
const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      "home",
      "ship",
      "ships",
      "stats",
      "component",
      "equipment-item",
    ].map((name) => ({
      path: name === "home" ? "/" : `/${name}/:slug?`,
      name,
      component: page,
    })),
  });

const mount = () => mountWithDefaults(Component, { plugins: [router()] });

const ship = (name: string) => ({
  id: `${name}-id`,
  name,
  slug: name.toLowerCase(),
  manufacturerName: "Roberts Space Industries",
});

const base = (): ScDataPatchSummary => ({
  from: { environment: "live", version: "4.10.1-live.1" },
  to: { environment: "live", version: "4.10.2-live.2" },
  counts: {
    newShips: 0,
    changedShips: 0,
    vanishedShips: 0,
    newComponents: 0,
    changedComponents: 0,
    newEquipment: 0,
    changedEquipment: 0,
    vanishedEquipment: 0,
  },
  newShips: [],
  latestArrivals: [],
  shipChanges: [],
  itemChanges: [],
});

const rebalanced = {
  model: ship("Andromeda"),
  fields: [
    { field: "mass", from: 386857, to: 367247 },
    { field: "hull_health", from: 180844, to: 103004 },
  ],
};

const row = async () => {
  const wrapper = await mount();

  return wrapper.get(".home-landing-patch__row").classes();
};

describe("HomeLandingPatch", () => {
  beforeEach(() => {
    summary.value = base();
    screens.value = [];
  });

  it("leads with the new ships and the biggest change", async () => {
    summary.value = {
      ...base(),
      newShips: [ship("Skylark")],
      shipChanges: [rebalanced],
    };

    expect(await row()).toContain("home-landing-patch__row--new");
  });

  it("leads with what moved most when the patch brought no ships", async () => {
    summary.value = { ...base(), shipChanges: [rebalanced] };

    expect(await row()).toContain("home-landing-patch__row--changes");
  });

  it("falls back to the newest arrivals when no ship changed", async () => {
    summary.value = {
      ...base(),
      latestArrivals: [ship("Skylark")],
      latestArrivalsVersion: "4.10.2-live.1",
    };

    expect(await row()).toContain("home-landing-patch__row--quiet");
  });

  it("names the biggest change first in the diff", async () => {
    summary.value = { ...base(), shipChanges: [rebalanced] };

    const wrapper = await mount();
    const line = wrapper.get(".home-landing-patch__line");

    expect(line.text()).toContain("Andromeda");
    expect(line.text()).toContain("Hull health");
  });

  it("opens the loading screen only when the build shipped one", async () => {
    let wrapper = await mount();
    expect(
      wrapper.get("[data-test='home-landing-patch-banner']").element.tagName,
    ).toBe("DIV");

    screens.value = [{ url: "/full.png", largeUrl: "/large.webp" }];
    wrapper = await mount();
    expect(
      wrapper.get("[data-test='home-landing-patch-banner']").element.tagName,
    ).toBe("BUTTON");
  });
});
