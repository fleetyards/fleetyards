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

const mountNav = async (
  props: Record<string, unknown>,
  slots: Record<string, string> = {},
) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", component: { template: "<div />" }, children: tabRoutes },
    ],
  });
  await router.push({ name: "vehicle-cargo" });
  await router.isReady();

  return mount(TabNavView, {
    props: { routes: tabRoutes, ...props },
    slots: { content: "<div />", ...slots },
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

      const wrapper = await mountNav({ horizontal: true });

      expect(wrapper.find(".tabs--horizontal").exists()).toBe(true);
      expect(wrapper.find(".tab-nav-dropdown").exists()).toBe(false);
    });

    it("folds the strip into the dropdown on a phone", async () => {
      setViewport(true);

      const wrapper = await mountNav({ horizontal: true });

      expect(wrapper.find(".tabs--horizontal").exists()).toBe(false);
      expect(wrapper.find(".tab-nav-dropdown").exists()).toBe(true);
    });
  });

  // A row a page adds after its tabs -- leaving the fleet -- has to survive the
  // fold into the dropdown, or a phone loses the action.
  describe("rows after the tabs", () => {
    const leaveRow = '<li data-test="leave"><a>Leave</a></li>';

    it("stays in the column on a desktop", async () => {
      setViewport(false);

      const wrapper = await mountNav({}, { "nav-after": leaveRow });

      expect(wrapper.find('.tabs [data-test="leave"]').exists()).toBe(true);
    });

    it("moves into the dropdown on a phone", async () => {
      setViewport(true);

      const wrapper = await mountNav({}, { "nav-after": leaveRow });

      await wrapper.find(".tab-nav-dropdown__trigger").trigger("click");

      expect(
        wrapper.find('.tab-nav-dropdown__panel [data-test="leave"]').exists(),
      ).toBe(true);
    });
  });
});
