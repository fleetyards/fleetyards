import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { LocationKindEnum, type Location } from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/locations/:slug",
        name: "location",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "home" });
  await instance.isReady();

  return instance;
};

const lorville = {
  id: "lorville",
  name: "Lorville",
  slug: "lorville",
  kind: LocationKindEnum.CITY,
  description: "Hurston Dynamics' company town.",
  quantumTravelDestination: true,
  childrenCount: 4,
  retired: false,
  ancestors: [
    {
      id: "stanton-system",
      name: "Stanton System",
      slug: "stanton-system",
      kind: LocationKindEnum.SYSTEM,
      parentName: null,
    },
    {
      id: "stanton",
      name: "Stanton",
      slug: "stanton",
      kind: LocationKindEnum.STAR,
      parentName: "Stanton System",
    },
    {
      id: "hurston",
      name: "Hurston",
      slug: "hurston",
      kind: LocationKindEnum.PLANET,
      parentName: "Stanton",
    },
  ],
} as unknown as Location;

describe("LocationStatsCard", () => {
  it("says what the place is, where it is, and what it holds", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { location: lorville },
      plugins: [await router()],
    });

    expect(wrapper.text()).toContain("Lorville");
    expect(wrapper.text()).toContain("Stanton System · Hurston");
    expect(wrapper.text()).not.toContain("Stanton ·");
    expect(wrapper.text()).toContain("Hurston Dynamics' company town.");
    expect(wrapper.text()).toContain("4");
  });

  it("marks a flare star unstable", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        location: {
          ...lorville,
          name: "Pyro",
          kind: LocationKindEnum.STAR,
          unstable: true,
        } as Location,
      },
      plugins: [await router()],
    });

    expect(wrapper.get("[data-test='stats-card-status']").text()).toBe(
      "Unstable",
    );
  });
});
