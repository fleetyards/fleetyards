import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const routerOn = async (name: string) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: ["hangar-paints", "hangar-flair", "hangar-buybacks"].map(
      (routeName) => ({
        path: `/${routeName}`,
        name: routeName,
        component: { template: "<div />" },
      }),
    ),
  });

  await router.push({ name });
  await router.isReady();

  return router;
};

describe("Hangar/PledgeItemsSwitch", () => {
  it("links paints, hangar flair and buy-backs, marking the current page", async () => {
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await routerOn("hangar-flair")],
    });

    const segments = ["paints", "flair", "buybacks"].map((key) =>
      wrapper.find(`[data-test='pledge-items-switch-${key}']`),
    );

    expect(segments.map((segment) => segment.attributes("href"))).toEqual([
      "#/hangar-paints",
      "#/hangar-flair",
      "#/hangar-buybacks",
    ]);
    expect(segments.map((segment) => segment.classes("active"))).toEqual([
      false,
      true,
      false,
    ]);
  });
});
