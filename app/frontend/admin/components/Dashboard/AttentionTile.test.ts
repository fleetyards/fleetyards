import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./AttentionTile.vue";

const Blank = { template: "<div />" };

const router = createRouter({
  history: createWebHashHistory(),
  routes: [{ path: "/workers/", name: "workers", component: Blank }],
});

const mountTile = async (props: Record<string, unknown>) => {
  await router.push("/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { count: 3, label: "Dead jobs", icon: "fa-skull", ...props },
    plugins: [router],
  });
};

describe("DashboardAttentionTile", () => {
  it("routes in place when given a route", async () => {
    const wrapper = await mountTile({ to: { name: "workers" } });

    const link = wrapper.find("a");

    expect(link.attributes("href")).toBe("#/workers/");
    expect(link.attributes("target")).toBeUndefined();
  });

  it("opens an engine mounted outside the app in a new tab", async () => {
    const wrapper = await mountTile({ href: "/admin/workers" });

    const link = wrapper.find("a");

    expect(link.attributes("href")).toBe("/admin/workers");
    expect(link.attributes("target")).toBe("_blank");
    expect(link.attributes("rel")).toBe("noopener");
  });
});
