import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Blueprint } from "@/services/fyApi";
import Component from "./index.vue";

// The row links to the recipe and back into the list it is being read from,
// and `filterLink` builds its target off the current route's name -- so the
// default single-route test router cannot resolve either.
const routerOnList = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/blueprints",
        name: "blueprints",
        component: { template: "<div />" },
      },
      {
        path: "/blueprints/:slug",
        name: "blueprint",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "blueprints" });
  await router.isReady();

  return router;
};

const ALIGNMENT = ".blueprint-row__alignment";

const blueprint = (attrs: Partial<Blueprint> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    name: "Bulldog Repeater",
    slug: "behr-repeater-s3",
    retired: false,
    sourceUnknown: false,
    sourceAlignments: ["lawful"],
    ...attrs,
  }) as Blueprint;

const mount = async (attrs: Partial<Blueprint> = {}) =>
  mountWithDefaults(Component, {
    props: { blueprint: blueprint(attrs) },
    plugins: [await routerOnList()],
  });

describe("Blueprints/Row", () => {
  it("says which side of the law hands the recipe out", async () => {
    const wrapper = await mount();

    const label = wrapper.find(ALIGNMENT);

    expect(label.text()).toBe("Lawful");
    expect(label.classes()).toContain("blueprint-row__alignment--lawful");
  });

  // Both sides hand out the same pool often enough that a row has to be able
  // to say two things at once.
  it("names every side a recipe is reachable from", async () => {
    const wrapper = await mount({ sourceAlignments: ["lawful", "outlaw"] });

    expect(wrapper.findAll(ALIGNMENT).map((label) => label.text())).toEqual([
      "Lawful",
      "Outlaw",
    ]);
  });

  // The value the catalogue can be narrowed by is the link that narrows it,
  // the way the row's materials and craftable type already are.
  it("links each side to the filter that asks for it", async () => {
    const wrapper = await mount({ sourceAlignments: ["outlaw"] });

    expect(wrapper.find(ALIGNMENT).attributes("href")).toContain("outlaw");
  });

  // 901 of the 1,607 recipes have no stated source, and the nine sources the
  // export leaves unattributed carry no side either -- both arrive empty, and
  // an empty run of labels would read as a rendering fault.
  it("says nothing where no side is stated", async () => {
    const wrapper = await mount({ sourceAlignments: [] });

    expect(wrapper.find(ALIGNMENT).exists()).toBe(false);
  });
});
