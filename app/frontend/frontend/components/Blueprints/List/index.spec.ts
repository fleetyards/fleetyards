import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Blueprint } from "@/services/fyApi";
import Component from "./index.vue";

const blueprint = (attrs: Partial<Blueprint> = {}) =>
  ({
    id: "id",
    name: "10-Series Greatsword Cannon",
    slug: "kbar-ballisticcannon-s2",
    scKey: "bp_craft_kbar_ballisticcannon_s2",
    scRef: "ref",
    retired: false,
    sourceUnknown: false,
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Blueprint;

// Its own router: the name links to `blueprint` and every material is a
// router-link onto the current route. TestUtils' default router knows only
// `home`, so both resolve to nothing and every row throws.
const mount = async (blueprints: Blueprint[]) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/catalogue/blueprints/",
        name: "blueprints",
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
    ],
  });
  await router.push({ name: "blueprints" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { blueprints },
    plugins: [router],
  });
};

describe("BlueprintsList", () => {
  it("renders a row per blueprint", async () => {
    const wrapper = await mount([blueprint(), blueprint({ slug: "other" })]);

    expect(wrapper.findAll(".blueprint-row")).toHaveLength(2);
  });

  describe("a row", () => {
    const row = async (attrs: Partial<Blueprint> = {}) =>
      (await mount([blueprint(attrs)])).find(".blueprint-row");

    it("links its name to the blueprint", async () => {
      expect(
        (await row()).find(".blueprint-row__name").attributes("href"),
      ).toContain("kbar-ballisticcannon-s2");
    });

    it("names the materials the recipe consumes", async () => {
      const found = await row({
        materials: [
          { id: "1", name: "Iron", slug: "iron" },
          { id: "2", name: "Titanium", slug: "titanium" },
        ],
      });

      expect(found.text()).toContain("Iron");
      expect(found.text()).toContain("Titanium");
    });

    // Each material narrows the catalogue to the recipes that use it, the way
    // a component row's manufacturer and category do.
    it("links a material to the recipes that use it", async () => {
      const found = await row({
        materials: [{ id: "1", name: "Iron", slug: "iron" }],
      });

      expect(
        found.find(".blueprint-row__material").attributes("href"),
      ).toContain("iron");
    });

    // The busiest recipe uses four, but the cap keeps a row one line if a
    // patch ever adds more.
    it("caps the materials and counts the rest", async () => {
      const found = await row({
        materials: [1, 2, 3, 4, 5, 6].map((n) => ({
          id: `${n}`,
          name: `Material ${n}`,
          slug: `material-${n}`,
        })),
      });

      expect(found.findAll(".blueprint-row__material")).toHaveLength(4);
      expect(found.find(".blueprint-row__material-more").text()).toBe("+2");
    });

    // 901 of the 1,607 recipes have no stated source, so "can I actually go
    // and get this" is a question the list itself has to answer.
    it("says so on a recipe nothing hands out", async () => {
      const found = await row({ sourceUnknown: true });

      expect(found.find(".blueprint-row__badge--quiet").exists()).toBe(true);
    });

    it("leaves the badge off a recipe that has a source", async () => {
      const found = await row({ sourceUnknown: false });

      expect(found.find(".blueprint-row__badge--quiet").exists()).toBe(false);
    });
  });
});
