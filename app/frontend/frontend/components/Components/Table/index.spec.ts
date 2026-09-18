import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Component as FyComponent } from "@/services/fyApi";
import Component from "./index.vue";

const component = (attrs: Partial<FyComponent> = {}) =>
  ({
    id: attrs.slug || "id",
    name: "A Part",
    slug: "a-part",
    hidden: false,
    retired: false,
    catalogued: true,
    availability: { boughtAt: [], soldAt: [] },
    media: {},
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as FyComponent;

// Its own router: the name cells link to `component`, and the sortable headings
// are router-links onto the current route. TestUtils' default router knows only
// `home`, so both resolve to nothing and every row throws.
const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/catalogue/components/",
        name: "components",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/components/:slug/",
        name: "component",
        component: { template: "<div />" },
      },
    ],
  });

const mount = async (components: FyComponent[]) => {
  const instance = router();
  await instance.push({ name: "components" });
  await instance.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { components },
    plugins: [instance],
  });
};

const headings = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll("th").map((th) => th.text().trim());

describe("ComponentsTable", () => {
  it("names its columns", async () => {
    const wrapper = await mount([component()]);

    expect(headings(wrapper)).toEqual(
      expect.arrayContaining(["Name", "Manufacturer", "Category", "Sub Type"]),
    );
  });

  // Size and grade hold the right edge, which is what a scan down a column of
  // rows is for. They were the first two before, buried mid-row.
  it("puts size and grade last", async () => {
    const wrapper = await mount([component()]);

    expect(headings(wrapper).slice(-2)).toEqual(["Size", "Grade"]);
  });

  // Every sortable heading renders a link; a plain heading does not. `size`
  // sorts through `sizeOrder`, a numeric ransacker, because the column itself
  // is a string and would order 10 and 12 ahead of 2.
  it("offers a sort on the columns the server can order by", async () => {
    const wrapper = await mount([component()]);

    const sorts = wrapper
      .findAll("th a")
      .map((link) => link.attributes("href") || "");

    [
      "name",
      "manufacturerName",
      "category",
      "componentSubType",
      "sizeOrder",
      "grade",
    ].forEach((field) => {
      expect(sorts.some((href) => href.includes(field))).toBe(true);
    });
  });

  describe("the metric columns", () => {
    // The question the catalogue exists to answer -- "shields by HP" -- needed a
    // column to be asked from. It appears only when the rows on screen carry
    // the figure.
    it("appear for a metric the rows carry, and sort", async () => {
      const wrapper = await mount([
        component({
          typeData: { maxHealth: 1000, maxRegen: 50 },
        } as Partial<FyComponent>),
      ]);

      expect(headings(wrapper)).toEqual(
        expect.arrayContaining(["HP", "Regen"]),
      );

      const sorts = wrapper
        .findAll("th a")
        .map((link) => link.attributes("href") || "");

      expect(sorts.some((href) => href.includes("maxHealth"))).toBe(true);
    });

    it("stay away when no row carries one", async () => {
      const wrapper = await mount([component()]);

      expect(headings(wrapper)).not.toEqual(
        expect.arrayContaining(["HP", "Regen"]),
      );
    });

    // With HP named at the top of its own column, repeating it per row under no
    // heading says the same thing twice.
    it("replace the unheaded per-row column rather than joining it", async () => {
      const withMetric = await mount([
        component({ typeData: { maxHealth: 1000 } } as Partial<FyComponent>),
      ]);

      expect(withMetric.find(".component-lead-metric").exists()).toBe(false);
    });
  });
});
