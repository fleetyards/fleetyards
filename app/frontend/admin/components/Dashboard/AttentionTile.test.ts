import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import {
  createRouter,
  createWebHashHistory,
  type RouteLocationRaw,
} from "vue-router";
import Component from "./AttentionTile.vue";

const Blank = { template: "<div />" };

const router = createRouter({
  history: createWebHashHistory(),
  routes: [{ path: "/jobs/", name: "workers", component: Blank }],
});

const mountTile = async (props: { to: RouteLocationRaw }) => {
  await router.push("/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { count: 3, label: "Dead jobs", icon: "fa-skull", ...props },
    plugins: [router],
  });
};

describe("DashboardAttentionTile", () => {
  it("routes in place when given a route", async () => {
    const wrapper = await mountTile({
      to: { name: "workers", query: { path: "/morgue" } },
    });

    const link = wrapper.find("a");

    expect(link.attributes("href")).toBe("#/jobs/?path=/morgue");
    expect(link.attributes("target")).toBeUndefined();
  });
});
