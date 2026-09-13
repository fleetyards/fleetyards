import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import {
  createMemoryHistory,
  createRouter,
  type RouteRecordRaw,
} from "vue-router";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import Component from "./index.vue";

const Stub = { template: "<div />" };

const ROUTES: RouteRecordRaw[] = [
  {
    path: "friends/",
    component: () => Promise.resolve({}),
    redirect: { name: "settings-friends" },
    meta: { title: "settings.friends" },
  } as RouteRecordRaw,
  {
    path: "privacy/",
    name: "settings-privacy",
    component: () => Promise.resolve({}),
    meta: { title: "settings.privacy" },
  } as RouteRecordRaw,
];

// The strip renders router-links, so the names its tabs point at have to
// resolve -- the default test router knows only the home route.
const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/settings/friends/", name: "settings-friends", component: Stub },
    { path: "/settings/privacy/", name: "settings-privacy", component: Stub },
  ],
});

const mountItems = (badges?: Record<string, number>) =>
  mountWithDefaults(Component, {
    props: { routes: ROUTES, authenticated: true, badges },
    plugins: [router],
  });

/*
 * A tab with requests waiting behind it says so, the way the nav row that leads
 * to the whole section does. A tab whose route is keyed by its redirect -- as
 * the friends one is -- has to be reachable by that name, or the count lands on
 * nothing.
 */
describe("TabNavViewItems", () => {
  it("counts beside the tab the requests wait behind", async () => {
    const wrapper = await mountItems({ "settings-friends": 3 });

    expect(wrapper.findAll(".tabs-badge").map((el) => el.text())).toEqual([
      "3",
    ]);
  });

  it("caps a count nobody reads precisely", async () => {
    const wrapper = await mountItems({ "settings-friends": 240 });

    expect(wrapper.find(".tabs-badge").text()).toBe("99+");
  });

  it("shows nothing at zero", async () => {
    const wrapper = await mountItems({ "settings-friends": 0 });

    expect(wrapper.find(".tabs-badge").exists()).toBe(false);
  });

  it("shows nothing when no counts are given", async () => {
    const wrapper = await mountItems();

    expect(wrapper.find(".tabs-badge").exists()).toBe(false);
  });
});
