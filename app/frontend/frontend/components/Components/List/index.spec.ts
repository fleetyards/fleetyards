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
const mount = async (
  components: FyComponent[],
  props: {
    gridView?: boolean;
    emptyVisible?: boolean;
    detailsVisible?: boolean;
  } = {},
) => {
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
    props: { components, ...props },
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

  it("puts the manufacturer's logo before its name in a row", async () => {
    const wrapper = await mount([
      component({
        manufacturer: {
          name: "Behring",
          slug: "behring",
          icon: { smallUrl: "https://example.test/behring.png" },
        },
      } as Partial<FyComponent>),
    ]);

    const link = wrapper.find(".row-list-item__sub a");

    expect(link.text()).toBe("Behring");
    expect(
      link.find("[data-test='component-row-maker-logo']").attributes("src"),
    ).toBe("https://example.test/behring.png");
  });

  it("leads a row with its store image in place of the category icon", async () => {
    const wrapper = await mount([
      component({
        category: "paints",
        media: { storeImage: { smallUrl: "https://example.test/small.jpg" } },
      } as Partial<FyComponent>),
    ]);

    expect(
      wrapper.find("[data-test='component-row-image']").attributes("src"),
    ).toBe("https://example.test/small.jpg");
    expect(wrapper.find(".hardpoint-category-icon").exists()).toBe(false);
  });

  it("keeps the category icon for a row without a store image", async () => {
    const wrapper = await mount([component({ category: "paints" })]);

    expect(wrapper.find("[data-test='component-row-image']").exists()).toBe(
      false,
    );
    expect(wrapper.find(".hardpoint-category-icon").exists()).toBe(true);
  });

  describe("as cards", () => {
    const card = async (attrs: Partial<FyComponent> = {}) =>
      (
        await mount(
          [
            component({
              category: "shieldgenerator",
              subType: "Gun",
              size: "1",
              gradeLabel: "A",
              manufacturer: { name: "Behring", slug: "behring" },
              ...attrs,
            } as Partial<FyComponent>),
          ],
          { gridView: true },
        )
      ).find("[data-test='component-card-a-part']");

    it("renders a card per component and no rows", async () => {
      const wrapper = await mount(
        [component(), component({ id: "id-2", slug: "b-part" })],
        { gridView: true },
      );

      expect(wrapper.findAll(".item-card")).toHaveLength(2);
      expect(wrapper.find(".component-row").exists()).toBe(false);
    });

    it("links its name to the component", async () => {
      expect(
        (await card()).find(".item-card__name").attributes("href"),
      ).toContain("a-part");
    });

    it("narrows the catalogue by its category pills", async () => {
      const hrefs = (await card())
        .findAll("[data-test='item-card-categories'] a")
        .map((link) => link.attributes("href") || "");

      expect(hrefs.join(" ")).toContain("categoryIn=shieldgenerator");
      expect(hrefs.join(" ")).toContain("componentSubTypeIn=Gun");
      expect(hrefs.join(" ")).not.toContain("manufacturerSlugIn");
    });

    it("shows the manufacturer's logo, naming it in full on hover", async () => {
      const maker = (
        await card({
          manufacturer: {
            name: "Behring",
            slug: "behring",
            code: "BEHR",
            icon: { smallUrl: "https://example.test/behring.png" },
          },
        } as Partial<FyComponent>)
      ).find("[data-test='item-card-maker']");

      expect(maker.attributes("aria-label")).toBe("Behring");
      expect(maker.attributes("href")).toContain("manufacturerSlugIn=behring");
      expect(maker.find("[data-test='item-card-logo']").attributes("src")).toBe(
        "https://example.test/behring.png",
      );
      expect(maker.text()).toBe("");
      expect(maker.find("[data-test='pill']").exists()).toBe(false);
    });

    it("falls back to the short code without a logo", async () => {
      const maker = (
        await card({
          manufacturer: { name: "Behring", slug: "behring", code: "BEHR" },
        } as Partial<FyComponent>)
      ).find("[data-test='item-card-maker']");

      expect(maker.text()).toBe("BEHR");
      expect(maker.find("[data-test='item-card-logo']").exists()).toBe(false);
    });

    it("falls back to the name without a logo or code", async () => {
      const maker = (await card()).find("[data-test='item-card-maker']");

      expect(maker.text()).toBe("Behring");
    });

    it("names the figure in its tiles", async () => {
      const tiles = (await card())
        .findAll(".metrics-card__tile")
        .map((tile) => [
          tile.find(".metrics-card__tile__label").text(),
          tile.find(".metrics-card__tile__value").text(),
        ]);

      expect(tiles).toEqual([
        ["Size", "1"],
        ["Grade", "A"],
      ]);
    });

    it("shows the store image in place of the category icon", async () => {
      const wrapper = await card({
        media: {
          storeImage: {
            smallUrl: "https://example.test/small.jpg",
            mediumUrl: "https://example.test/medium.jpg",
          },
        },
      } as Partial<FyComponent>);

      expect(
        wrapper.find("[data-test='item-card-image']").attributes("src"),
      ).toBe("https://example.test/medium.jpg");
      expect(wrapper.find(".hardpoint-category-icon").exists()).toBe(false);
    });

    it("keeps the category icon for a component without a store image", async () => {
      const wrapper = await card();

      expect(wrapper.find("[data-test='item-card-image']").exists()).toBe(
        false,
      );
      expect(wrapper.find(".hardpoint-category-icon").exists()).toBe(true);
    });

    // A component the game never named has no slug, and `router-link` throws
    // on a missing required param.
    it("prints the name of a component without a slug as plain text", async () => {
      const wrapper = await mount([component({ slug: "" })], {
        gridView: true,
      });

      const name = wrapper.find(".item-card__name");

      expect(name.element.tagName).toBe("SPAN");
      expect(name.text()).toBe("A Part");
    });

    it("says the list is empty rather than drawing an empty grid", async () => {
      const wrapper = await mount([], { gridView: true, emptyVisible: true });

      expect(wrapper.find(".item-card").exists()).toBe(false);
      expect(wrapper.findComponent({ name: "Empty" }).exists()).toBe(true);
    });

    // As on a ship card: the picture and the name, and the figures only once
    // the reader asks for them.
    it("hides the figures until details are on", async () => {
      const hidden = await mount([component({ size: "1" })], {
        gridView: true,
      });
      const shown = await mount([component({ size: "1" })], {
        gridView: true,
        detailsVisible: true,
      });

      const details = (wrapper: typeof hidden) =>
        wrapper.find("[data-test='item-card-details']").element.parentElement
          ?.style.display;

      expect(details(hidden)).toBe("none");
      expect(details(shown)).not.toBe("none");
    });
  });
});
