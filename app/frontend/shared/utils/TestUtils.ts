import { mount, flushPromises } from "@vue/test-utils";
import { Plugin } from "vue";
import { createTestingPinia, TestingOptions } from "@pinia/testing";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { createRouter, createWebHashHistory, type Router } from "vue-router";
import VueLazyload from "vue-lazyload";

const createPinia = (newState: TestingOptions["initialState"]) =>
  createTestingPinia({
    initialState: {
      user: { user: { id: 1, email: "", enabledFeatures: [] } },
      apps: { apps: [{ namespace: "classroom_screen", color: "#fff" }] },
      ...newState,
    },
  });

const isVueRouter = (plugin: Plugin): plugin is Router => {
  return (plugin as Router).push !== undefined;
};

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: "/",
      name: "home",
      component: () => import("@/frontend/pages/index.vue"),
    },
  ],
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const mountWithDefaults = async <C extends new (...args: any) => any>(
  component: C,
  params?: {
    props?: InstanceType<C>["$props"];
    slots?: InstanceType<C>["$slots"];
    initialState?: TestingOptions["initialState"];
    plugins?: Plugin[];
  },
) => {
  // Do not redefine vue-router
  const hasVueRouter = params?.plugins?.some((plugin) => isVueRouter(plugin));
  const withRouter = !hasVueRouter ? [router] : [];

  const wrapper = mount(component, {
    props: params?.props,
    slots: params?.slots,
    global: {
      plugins: [
        VueLazyload,
        createPinia(params?.initialState || {}),
        VueQueryPlugin,
        ...withRouter,
        ...(params?.plugins || []),
      ],
      directives: {
        Tooltip: {}, // Tooltip matches v-tooltip
      },
    },
  });
  await flushPromises(); // Wait for promises to resolve
  return wrapper;
};
