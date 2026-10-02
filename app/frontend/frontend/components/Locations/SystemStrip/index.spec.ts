import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { LocationKindEnum, type LocationTreeNode } from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/locations/:slug",
        name: "location",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "location", params: { slug: "levski" } });
  await instance.isReady();

  return instance;
};

const node = (
  id: string,
  name: string,
  kind: LocationKindEnum,
  children: LocationTreeNode[] = [],
  extra: Partial<LocationTreeNode> = {},
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
  ...extra,
});

const nyx = node("nyx-system", "Nyx System", LocationKindEnum.SYSTEM, [
  node(
    "nyx",
    "Nyx",
    LocationKindEnum.STAR,
    [
      node("nyx-1", "Nyx I", LocationKindEnum.PLANET),
      node("delamar", "Delamar", LocationKindEnum.MOON, [
        node("levski", "Levski", LocationKindEnum.CITY),
      ]),
    ],
    {
      gateways: [
        {
          id: "pyro-gateway",
          name: "Pyro Gateway",
          slug: "pyro-gateway",
          kind: LocationKindEnum.STATION,
          parentName: "Nyx",
        },
      ],
    },
  ),
]);

const mount = async (props: Record<string, unknown>) =>
  mountWithDefaults(Component, {
    props: { tree: nyx, ...props },
    plugins: [await router()],
  });

describe("LocationSystemStrip", () => {
  it("lays the bodies out from the star in orbit order", async () => {
    const wrapper = await mount({});

    const names = wrapper
      .findAll(".location-strip__body .location-strip__name")
      .map((name) => name.text());

    expect(names).toEqual(["Nyx I", "Delamar"]);
    expect(wrapper.text()).toContain("Pyro Gateway");
  });

  it("lights the path, lists the lit body's moons and cities and keeps the jump points when compact", async () => {
    const wrapper = await mount({
      compact: true,
      path: ["nyx-system", "nyx", "delamar", "levski"],
    });

    expect(wrapper.find(".location-strip__body--lit").text()).toContain(
      "Delamar",
    );
    expect(wrapper.find(".location-strip__moon--lit").text()).toBe("Levski");
    expect(wrapper.text()).toContain("Pyro Gateway");
  });
});
