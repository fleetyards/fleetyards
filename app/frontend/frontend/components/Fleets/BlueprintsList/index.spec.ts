import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type Blueprint,
  type FleetBlueprint,
  type FleetBlueprintOwner,
} from "@/services/fyApi";
import Component from "./index.vue";

const blueprint = (attrs: Partial<Blueprint> = {}) =>
  ({
    id: "id",
    name: "10-Series Greatsword Cannon",
    slug: "kbar-ballisticcannon-s2",
    scKey: "bp_craft_kbar_ballisticcannon_s2",
    scRef: "ref",
    retired: false,
    owned: false,
    sourceUnknown: false,
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Blueprint;

const owner = (attrs: Partial<FleetBlueprintOwner> = {}) => ({
  userId: "user-id",
  username: "crafter",
  ...attrs,
});

const row = (attrs: Partial<FleetBlueprint> = {}): FleetBlueprint => ({
  id: "id",
  blueprint: blueprint(),
  ownerCount: 1,
  owners: [owner()],
  ...attrs,
});

// Its own router, like the catalogue's list spec: the row links to the recipe,
// to every material and now to each owner's hangar, and TestUtils' default
// router knows only `home`.
const mount = async (blueprints: FleetBlueprint[]) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/fleets/:slug/blueprints/",
        name: "fleet-blueprints",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/blueprints/:slug/",
        name: "blueprint",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/components/:slug/",
        name: "component",
        component: { template: "<div />" },
      },
      {
        path: "/hangar/:username/",
        name: "hangar-public",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push({ name: "fleet-blueprints", params: { slug: "acme" } });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { blueprints },
    plugins: [router],
  });
};

describe("FleetBlueprintsList", () => {
  it("renders a row per recipe the members hold", async () => {
    const wrapper = await mount([
      row(),
      row({ id: "other", blueprint: blueprint({ id: "other" }) }),
    ]);

    expect(wrapper.findAll(".blueprint-row")).toHaveLength(2);
  });

  it("names who holds it", async () => {
    const wrapper = await mount([
      row({
        ownerCount: 2,
        owners: [
          owner(),
          owner({ userId: "second", username: "second", nickname: "Nick" }),
        ],
      }),
    ]);

    const owners = wrapper.findAll(".blueprint-row__owner");

    expect(owners).toHaveLength(2);
    // The fleet's name for somebody wins where it has one.
    expect(owners.map((link) => link.text())).toEqual(["crafter", "Nick"]);
  });

  // A fleet of crafters would otherwise turn one row into a paragraph.
  it("caps the names and counts the rest", async () => {
    const wrapper = await mount([
      row({
        ownerCount: 9,
        owners: Array.from({ length: 9 }, (_, at) =>
          owner({ userId: `user-${at}`, username: `crafter-${at}` }),
        ),
      }),
    ]);

    expect(wrapper.findAll(".blueprint-row__owner")).toHaveLength(3);
    expect(wrapper.find(".blueprint-row__owner-more").text()).toBe("+6");
  });
});
