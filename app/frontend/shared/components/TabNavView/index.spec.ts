import { mount } from "@vue/test-utils";
import { beforeAll, describe, expect, it, vi } from "vitest";
import { createPinia } from "pinia";
import {
  createMemoryHistory,
  createRouter,
  type RouteRecordRaw,
} from "vue-router";
import TabNavView from "./index.vue";

const tabRoutes: RouteRecordRaw[] = [
  {
    path: "cargo",
    name: "vehicle-cargo",
    component: { template: "<div />" },
    meta: { title: "cargo" },
  },
  {
    path: "loadouts",
    name: "vehicle-loadouts",
    component: { template: "<div />" },
    meta: { title: "loadouts" },
  },
];

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

const mountHorizontal = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", component: { template: "<div />" }, children: tabRoutes },
    ],
  });
  await router.push({ name: "vehicle-cargo" });
  await router.isReady();

  return mount(TabNavView, {
    props: { routes: tabRoutes, horizontal: true },
    slots: { content: "<div />" },
    global: { plugins: [router, createPinia()] },
  });
};

beforeAll(() => {
  Element.prototype.scrollTo = vi.fn();
});

describe("TabNavView", () => {
  describe("horizontal", () => {
    it("keeps the strip on a desktop", async () => {
      setViewport(false);

      const wrapper = await mountHorizontal();

      expect(wrapper.find(".tabs--horizontal").exists()).toBe(true);
      expect(wrapper.find(".tab-nav-dropdown").exists()).toBe(false);
    });

    it("folds the strip into the dropdown on a phone", async () => {
      setViewport(true);

      const wrapper = await mountHorizontal();

      expect(wrapper.find(".tabs--horizontal").exists()).toBe(false);
      expect(wrapper.find(".tab-nav-dropdown").exists()).toBe(true);
    });
  });
});
