import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/ships/:slug",
        name: "ship",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/missions/:slug",
        name: "mission",
        component: { template: "<div />" },
      },
    ],
  });

describe("CatalogueTokenLink", () => {
  it("marks an item with its type's icon and its name in brackets", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        item: { type: "Model", slug: "anvl-carrack", name: "Carrack" },
      },
      plugins: [router()],
    });

    expect(wrapper.find(".duotone-glyph").exists()).toBe(true);
    expect(wrapper.text()).toBe("[Carrack]");
  });

  it("reads a mission's placeholders the way the mission list does", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        item: {
          type: "GameMission",
          slug: "ambush",
          name: "Ambush at ~mission(Location|Address)",
        },
      },
      plugins: [router()],
    });

    expect(wrapper.text()).not.toContain("~mission(");
    expect(wrapper.find(".mission-text__token").exists()).toBe(true);
  });
});
