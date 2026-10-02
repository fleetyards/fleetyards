import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { LocationKindEnum, type LocationTreeNode } from "@/services/fyApi";
import Component from "./index.vue";

const node = (
  id: string,
  name: string,
  kind: LocationKindEnum,
  children: LocationTreeNode[] = [],
): LocationTreeNode => ({
  location: {
    id,
    name,
    slug: id,
    kind,
    parentName: null,
    shownOnStarmap: true,
    color: null,
  },
  counts: [],
  lagrangePoints: [],
  gateways: [],
  children,
});

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

describe("LocationBodyColumns", () => {
  it("links a city on a moon to the city, not the moon", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        bodies: [
          node("nyx-i", "Nyx I", LocationKindEnum.PLANET, [
            node("delamar", "Delamar", LocationKindEnum.MOON, [
              node("levski", "Levski", LocationKindEnum.CITY),
            ]),
          ]),
        ],
      },
      plugins: [await router()],
    });

    expect(
      wrapper.get(".location-columns__moon-city").attributes("href"),
    ).toContain("/locations/levski");
    expect(
      wrapper.get(".location-columns__moon-name").attributes("href"),
    ).toContain("/locations/delamar");
    expect(wrapper.findAll(".location-columns__moon a a")).toHaveLength(0);
  });
});
