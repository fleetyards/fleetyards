import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { createRouter, createWebHashHistory } from "vue-router";
import type { RouteLocationNormalizedLoaded, RouteRecordRaw } from "vue-router";
import Component from "./index.vue";

const Blank = { template: "<div />" };

const routes = [
  {
    path: "/models/",
    component: Blank,
    meta: { title: "models", icon: "fa-duotone fa-starship" },
    children: [
      { path: "", name: "models", component: Blank, meta: { title: "index" } },
      {
        path: "unlisted",
        name: "models-unlisted",
        component: Blank,
        meta: { title: "unlisted" },
      },
    ],
  },
  {
    path: "/pghero/",
    name: "pghero",
    component: Blank,
    meta: { title: "pghero", href: "/admin/pghero" },
  },
] as RouteRecordRaw[];

const currentRoute = {
  name: "models",
  meta: {},
} as RouteLocationNormalizedLoaded;

const mountItems = async (props: Record<string, unknown>) => {
  const router = createRouter({ history: createWebHashHistory(), routes });
  await router.push("/models/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { routes, currentRoute, ...props },
    plugins: [router],
  });
};

describe("AppNavigationItems", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("expands a route with several children into a submenu", async () => {
    const wrapper = await mountItems({});

    expect(wrapper.find(".nav-item__sub-menu").exists()).toBe(true);
  });

  it("opens a route with an external href in a new tab", async () => {
    const wrapper = await mountItems({});

    const link = wrapper.find('[data-test="nav-pghero"] a');

    expect(link.attributes("href")).toBe("/admin/pghero");
    expect(link.attributes("target")).toBe("_blank");
  });

  it("links straight to the first child when submenus are hidden", async () => {
    const wrapper = await mountItems({ hideSubmenus: true });

    expect(wrapper.find(".nav-item__sub-menu").exists()).toBe(false);
    expect(wrapper.find("a").attributes("href")).toBe("#/models/");
  });
});
