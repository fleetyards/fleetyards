import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import { type Vehicle } from "@/services/fyApi";

const mutateAsync = vi.fn(() => Promise.resolve());

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync, isPending: ref(false) }),
  }),
}));

const NOW = "2026-10-13T12:00:00Z";

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    alternativeNames: [],
    hangarGroupIds: [],
    hangarGroups: [],
    modelModuleIds: [],
    modelUpgradeIds: [],
    manufacturerCode: "DRAK",
    model: {
      id: "model-1",
      name: "Corsair",
      slug: "corsair",
      media: {},
      manufacturer: {
        name: "Drake Interplanetary",
        slug: "drake",
        code: "DRAK",
        createdAt: NOW,
        updatedAt: NOW,
      },
    },
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  }) as Vehicle;

// The upsell links to the support page, which the test router has to know.
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/support", name: "support", component: { template: "<div />" } },
  ],
});

const mount = (supporter: boolean) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { vehicle: vehicle() },
    initialState: { session: { currentUser: { supporter } } },
    plugins: [router],
  });

const openStyles = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
  await wrapper
    .find('[data-test="vehicle-plaque-styles-open"]')
    .trigger("click");
};

const styleTile = (wrapper: Awaited<ReturnType<typeof mount>>, style: string) =>
  wrapper.find(`[data-test="vehicle-plaque-style-${style}"]`);

describe("VehiclePlaqueEditModal", () => {
  it("previews every style on a page of its own", async () => {
    const wrapper = await mount(true);
    await openStyles(wrapper);

    expect(
      wrapper.findAll(
        '[data-test="vehicle-plaque-styles"] [data-test="vehicle-plaque"]',
      ),
    ).toHaveLength(10);
  });

  it("leaves a non-supporter brass and greys out the rest", async () => {
    const wrapper = await mount(false);
    await openStyles(wrapper);

    expect(styleTile(wrapper, "brass").attributes("aria-disabled")).toBe(
      "false",
    );
    expect(styleTile(wrapper, "neon").attributes("aria-disabled")).toBe("true");
    expect(wrapper.find('[data-test="vehicle-plaque-upsell"]').exists()).toBe(
      true,
    );

    expect(wrapper.find(".plaque-edit__locked--open").exists()).toBe(false);

    await styleTile(wrapper, "neon").trigger("click");

    expect(wrapper.find(".plaque-edit__locked--open").exists()).toBe(true);

    expect(styleTile(wrapper, "neon").attributes("aria-pressed")).toBe("false");
    expect(styleTile(wrapper, "brass").attributes("aria-pressed")).toBe("true");
  });

  it("starts a supporter on the maker's own style", async () => {
    const wrapper = await mount(true);
    await openStyles(wrapper);

    expect(styleTile(wrapper, "manufacturer").attributes("aria-pressed")).toBe(
      "true",
    );
    expect(wrapper.find('[data-test="vehicle-plaque-upsell"]').exists()).toBe(
      false,
    );
  });
});
