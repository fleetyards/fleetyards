import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Location, LocationKindEnum } from "@/services/fyApi";
import Component from "./index.vue";

const routerOn = async (
  name: "locations-places" | "location",
  query: Record<string, string> = {},
) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/locations/places",
        name: "locations-places",
        component: { template: "<div />" },
      },
      {
        path: "/locations/:slug",
        name: "location",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push(
    name === "location"
      ? { name, params: { slug: "aberdeen" }, query }
      : { name, query },
  );
  await router.isReady();

  return router;
};

const location = (attrs: Partial<Location> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    name: "Outpost 54",
    slug: "outpost-54-aberdeen",
    kind: LocationKindEnum.OUTPOST,
    scKey: "MiningFacility_Stanton1b_Reyes",
    retired: false,
    shownOnStarmap: true,
    shownWithParentOnly: true,
    alwaysShown: false,
    quantumTravelDestination: true,
    parent: {
      id: "1f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
      name: "Aberdeen",
      slug: "aberdeen",
      kind: LocationKindEnum.MOON,
      parentName: "Hurston",
    },
    createdAt: "2026-10-01T00:00:00Z",
    updatedAt: "2026-10-01T00:00:00Z",
    ...attrs,
  }) as Location;

const mount = async (attrs: Partial<Location> = {}) =>
  mountWithDefaults(Component, {
    props: { location: location(attrs) },
    plugins: [await routerOn("locations-places")],
  });

describe("LocationRow", () => {
  // Two Outpost 54s sit on Aberdeen; the parent is what a reader tells them
  // apart by.
  it("names the parent beside a place", async () => {
    const wrapper = await mount();

    expect(wrapper.text()).toContain("Outpost 54");
    expect(wrapper.text()).toContain("Aberdeen");
    expect(wrapper.text()).toContain("Hurston");
  });

  // The same row lists what sits inside a place on that place's page, where
  // filtering the page's own route would change nothing.
  it("filters the list by kind from wherever the row is", async () => {
    const wrapper = await mount();

    const tag = wrapper.find('a[href*="kindIn"]');

    expect(tag.attributes("href")).toContain(
      "/locations/places?kindIn=outpost",
    );
  });

  it("leaves a place page's own query behind when it filters the list", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { location: location() },
      plugins: [await routerOn("location", { tab: "missions" })],
    });

    const href = wrapper.find('a[href*="kindIn"]').attributes("href");

    expect(href).toContain("/locations/places?kindIn=outpost");
    expect(href).not.toContain("tab=");
  });

  it("marks a place hidden on the in-game map", async () => {
    const wrapper = await mount({ shownOnStarmap: false });

    expect(wrapper.text()).toContain("Hidden on the map");
  });

  it("marks a place the map always shows", async () => {
    const wrapper = await mount({ alwaysShown: true });

    expect(wrapper.text()).toContain("Always on the map");
    expect(wrapper.text()).not.toContain("Hidden on the map");
  });

  it("names a system without a parent", async () => {
    const wrapper = await mount({
      name: "Stanton System",
      kind: LocationKindEnum.SYSTEM,
      parent: null,
    });

    expect(wrapper.text()).toContain("Star system");
  });
});
