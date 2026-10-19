import { beforeEach, describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const routerOn = async (name: string) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      "hangar-paints",
      "hangar-flair",
      "hangar-equipment",
      "hangar-ship-components",
      "hangar-upgrades",
      "hangar-buybacks",
    ].map((routeName) => ({
      path: `/${routeName}`,
      name: routeName,
      component: { template: "<div />" },
    })),
  });

  await router.push({ name });
  await router.isReady();

  return router;
};

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

describe("Hangar/PledgeItemsSwitch", () => {
  beforeEach(() => {
    setViewport(false);
  });

  it("links paints, hangar flair, equipment, ship components and buy-backs, marking the current page", async () => {
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await routerOn("hangar-flair")],
    });

    const segments = [
      "paints",
      "flair",
      "equipment",
      "shipComponents",
      "upgrades",
      "buybacks",
    ].map((key) => wrapper.find(`[data-test='pledge-items-switch-${key}']`));

    expect(segments.map((segment) => segment.attributes("href"))).toEqual([
      "#/hangar-paints",
      "#/hangar-flair",
      "#/hangar-equipment",
      "#/hangar-ship-components",
      "#/hangar-upgrades",
      "#/hangar-buybacks",
    ]);
    expect(segments.map((segment) => segment.classes("active"))).toEqual([
      false,
      true,
      false,
      false,
      false,
      false,
    ]);
  });

  it("collapses into one button for the current list on a phone", async () => {
    setViewport(true);

    const wrapper = await mountWithDefaults(Component, {
      plugins: [await routerOn("hangar-equipment")],
    });

    const menu = wrapper.find("[data-test='pledge-items-switch-menu']");

    expect(menu.exists()).toBe(true);
    expect(menu.find(".fa-shirt").exists()).toBe(true);
    expect(wrapper.find(".btn-group").exists()).toBe(false);
  });
});
