import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type LocationContentsGroup, LocationKindEnum } from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/locations",
        name: "locations",
        component: { template: "<div />" },
      },
      {
        path: "/locations/:slug",
        name: "location",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "locations" });
  await instance.isReady();

  return instance;
};

const groups: LocationContentsGroup[] = [
  {
    kind: LocationKindEnum.OUTPOST,
    count: 307,
    entries: [
      {
        name: "QV Logistics Station",
        count: 306,
        shownOnStarmap: false,
        location: {
          id: "kaboos-1",
          name: "QV Logistics Station",
          slug: "qv-logistics-station-nyx",
          kind: LocationKindEnum.OUTPOST,
          parentName: "Nyx",
        },
      },
      {
        name: "Mercy Hospital",
        count: 1,
        shownOnStarmap: true,
        location: {
          id: "mercy",
          name: "Mercy Hospital",
          slug: "mercy-hospital",
          kind: LocationKindEnum.OUTPOST,
          parentName: "Levski",
        },
      },
    ],
  },
];

describe("LocationContentsList", () => {
  it("folds namesakes into one row that opens the list of all of them", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { groups, parentId: "nyx" },
      plugins: [await router()],
    });

    const links = wrapper.findAll("a").map((link) => link.attributes("href"));

    expect(wrapper.text()).toContain("×306");
    expect(links.some((href) => href?.includes("nameIn"))).toBe(true);
    expect(links).toContain("#/locations/mercy-hospital");
    expect(wrapper.text()).toContain("Hidden on the map");
  });
});
