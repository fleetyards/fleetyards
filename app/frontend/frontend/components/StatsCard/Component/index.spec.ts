import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { Component } from "@/services/fyApi";
import ComponentStatsCard from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/components/:slug",
        name: "component",
        component: { template: "<div />" },
      },
    ],
  });

const drive = {
  id: "1",
  name: "Torrent",
  slug: "torrent",
  category: "quantumdrive",
  typeData: {
    driveSpeed: 263_400_000,
    splineJumpParams: { driveSpeed: 400_000, spoolUpTime: 6 },
  },
} as unknown as Component;

const mount = (compact: boolean) =>
  mountWithDefaults(ComponentStatsCard, {
    props: { component: drive, compact },
    plugins: [router()],
  });

describe("ComponentStatsCard", () => {
  it("keeps a drive's orbit-jump figures when floating over a list", async () => {
    const wrapper = await mount(true);

    expect(wrapper.text()).toContain("Orbit Spool Up");
  });

  it("leaves them to their own card on the detail page", async () => {
    const wrapper = await mount(false);

    expect(wrapper.text()).not.toContain("Orbit Spool Up");
  });
});
