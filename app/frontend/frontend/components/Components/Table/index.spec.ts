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

  // A bare "1" or "A" says nothing once it is away from its heading -- on a
  // phone, in a screenshot, or to anyone scanning the right-hand edge rather
  // than reading across.
  it("names the figure inside the size and grade badges", async () => {
    const wrapper = await mount([
      component({ size: "1", gradeLabel: "A" } as Partial<FyComponent>),
    ]);

    // Asserted per span rather than on the badge's text: the label and the
    // value are separated by a flex `gap`, so the rendered text runs them
    // together as "Size1" with no node between them.
    const badges = wrapper
      .findAll(".components-table__badge")
      .map((badge) => [
        badge.find(".components-table__badge-label").text(),
        badge.find(".components-table__badge-value").text(),
      ]);

    expect(badges).toEqual([
      ["Size", "1"],
      ["Grade", "A"],
    ]);
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

  // Clicking a value the catalogue can be narrowed by narrows it. The filters
  // live in the route query, so these are plain links -- shareable, undone by
  // the back button, and read back by the filter form.
  // A heading is only a sort control while it is on screen, and the table
  // scrolls sideways on a narrow window. The line above it stays put, and runs
  // through the same composable, so the two cannot disagree about what is
  // active.
  describe("the sort line", () => {
    it("offers a chip for every sortable column", async () => {
      const wrapper = await mount([component()]);

      const chips = wrapper
        .findAll(".base-table-sort-chip")
        .map((chip) => chip.text().trim());

      expect(chips).toEqual([
        "Name",
        "Manufacturer",
        "Category",
        "Sub Type",
        "Size",
        "Grade",
      ]);
    });

    // The metric columns come and go with the rows on screen; their chips have
    // to come with them, or the line offers a sort for a column that is not
    // there.
    it("gains a chip when a metric column appears", async () => {
      const wrapper = await mount([
        component({ typeData: { maxHealth: 1000 } } as Partial<FyComponent>),
      ]);

      const chips = wrapper
        .findAll(".base-table-sort-chip")
        .map((chip) => chip.text().trim());

      expect(chips).toContain("HP");
    });

    it("sorts by the same field the heading does", async () => {
      const wrapper = await mount([component()]);

      const chip = wrapper
        .findAll(".base-table-sort-chip")
        .find((link) => link.text().trim() === "Size");

      expect(chip?.attributes("href")).toContain("sizeOrder");
    });

    // The unheaded columns -- the icon, and the per-row metric figure -- have
    // nothing to label a chip with and nothing to sort by.
    it("leaves out the columns with no heading", async () => {
      const wrapper = await mount([component()]);

      wrapper.findAll(".base-table-sort-chip").forEach((chip) => {
        expect(chip.text().trim()).not.toBe("");
      });
    });
  });

  describe("click to filter", () => {
    const hrefFor = async (column: string) => {
      const wrapper = await mount([
        component({
          category: "shieldgenerator",
          subType: "Gun",
          manufacturer: { name: "Behring", slug: "behring" },
        } as Partial<FyComponent>),
      ]);

      // `td` rather than `tbody td`: VTU stubs `transition-group`, which is
      // what BaseTable renders its body with, so no literal tbody exists in the
      // markup. `th` and `td` still separate header from body.
      const cells = wrapper.findAll("td");
      const index = headings(wrapper).indexOf(column);

      return cells[index]?.find("a").attributes("href") || "";
    };

    it("narrows by category", async () => {
      expect(await hrefFor("Category")).toContain("categoryIn=shieldgenerator");
    });

    it("narrows by sub type", async () => {
      expect(await hrefFor("Sub Type")).toContain("componentSubTypeIn=Gun");
    });

    it("narrows by manufacturer", async () => {
      expect(await hrefFor("Manufacturer")).toContain(
        "manufacturerNameCont=Behring",
      );
    });

    // The name is the link to the component itself. Filtering the catalogue
    // down to the row you are already looking at is not a thing anyone wants.
    it("leaves the name linking to the component", async () => {
      expect(await hrefFor("Name")).toContain("a-part");
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
    //
    // Counted by unheaded columns rather than by the absence of the per-row
    // component: that renders nothing for a component carrying no figures at
    // all, so asserting it is missing would pass whether or not this works.
    // Two unheaded columns means icon + per-row metrics; one means icon alone.
    it("replace the unheaded per-row column rather than joining it", async () => {
      const unheaded = async (record: FyComponent) =>
        headings(await mount([record])).filter((heading) => heading === "")
          .length;

      expect(await unheaded(component())).toBe(2);
      expect(
        await unheaded(
          component({ typeData: { maxHealth: 1000 } } as Partial<FyComponent>),
        ),
      ).toBe(1);
    });
  });
});
