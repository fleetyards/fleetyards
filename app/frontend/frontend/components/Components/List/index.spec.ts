import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Component as FyComponent } from "@/services/fyApi";
import Component from "./index.vue";

const component = (attrs: Partial<FyComponent> = {}) =>
  ({
    id: "id",
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

// Its own router: the name links to `component` and every sort chip is a
// router-link onto the current route. TestUtils' default router knows only
// `home`, so both resolve to nothing and every row throws.
const mount = async (components: FyComponent[]) => {
  const router = createRouter({
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
  await router.push({ name: "components" });
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { components },
    plugins: [router],
  });
};

describe("ComponentsList", () => {
  it("renders a row per component", async () => {
    const wrapper = await mount([component(), component({ slug: "b-part" })]);

    expect(wrapper.findAll(".component-row")).toHaveLength(2);
  });

  describe("a row", () => {
    const row = async () =>
      (
        await mount([
          component({
            category: "shieldgenerator",
            subType: "Gun",
            size: "1",
            gradeLabel: "A",
            manufacturer: { name: "Behring", slug: "behring" },
          } as Partial<FyComponent>),
        ])
      ).find(".component-row");

    it("links its name to the component", async () => {
      expect(
        (await row()).find(".row-list-item__name").attributes("href"),
      ).toContain("a-part");
    });

    // An anchor inside an anchor is invalid and does not work, which is why the
    // row is a container rather than one big link.
    it("narrows the catalogue by the values beside the name", async () => {
      const hrefs = (await row())
        .findAll(".row-list-item__sub a")
        .map((link) => link.attributes("href") || "");

      expect(hrefs.join(" ")).toContain("manufacturerSlugIn=behring");
      expect(hrefs.join(" ")).toContain("categoryIn=shieldgenerator");
      expect(hrefs.join(" ")).toContain("componentSubTypeIn=Gun");
    });

    // A row has no column heading above it to say which figure a bare "1" is.
    it("names the figure in its badges", async () => {
      const badges = (await row())
        .findAll(".row-list-item__badge")
        .map((badge) => [
          badge.find(".row-list-item__badge-label").text(),
          badge.find(".row-list-item__badge-value").text(),
        ]);

      expect(badges).toEqual([
        ["Size", "1"],
        ["Grade", "A"],
      ]);
    });
  });
});
