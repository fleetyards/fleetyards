import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

// The viewer pulls three.js in, which the test environment cannot load.
vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  default: { name: "HoloViewer", template: "<div />" },
}));

vi.mock("@/frontend/components/Vehicles/ContextMenu/index.vue", () => ({
  default: { name: "VehicleContextMenu", template: "<div />" },
}));

const vehicle = {
  id: "vehicle-1",
  name: "Rust Bucket",
  serial: "IC-021",
  location: "Lorville",
  boughtVia: BoughtViaEnum.PLEDGE_STORE,
  flagship: true,
  public: true,
  wanted: false,
  loaner: false,
  model: {
    id: "model-1",
    name: "Ironclad",
    slug: "ironclad",
    media: {},
    metrics: { length: 123 },
    speeds: {},
    manufacturer: { id: "manufacturer-1", name: "Drake", slug: "drake" },
  },
  createdAt: "2026-10-12T12:00:00Z",
} as unknown as Vehicle;

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "hangar", component: { template: "<div />" } },
    { path: "/ships/:slug", name: "ship", component: { template: "<div />" } },
  ],
});

const mount = (compact: boolean) =>
  mountWithDefaults(Component, {
    props: { vehicle, compact },
    plugins: [router],
  });

describe("VehicleHero", () => {
  it("names the ship and where it is", async () => {
    const wrapper = await mount(false);

    expect(wrapper.find("h1").text()).toBe("Rust Bucket");
    expect(
      wrapper.find('[data-test="vehicle-hero-location"]').text(),
    ).toContain("Lorville");
  });

  it("shrinks into the banner without leaving the page", async () => {
    const wrapper = await mount(false);

    expect(wrapper.classes()).not.toContain("vehicle-hero--compact");

    await wrapper.setProps({ compact: true });

    expect(wrapper.classes()).toContain("vehicle-hero--compact");
    expect(wrapper.find("h1").text()).toBe("Rust Bucket");
  });
});
