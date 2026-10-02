import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/catalogue/commodities/:slug",
        name: "commodity",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "home" });
  await instance.isReady();

  return instance;
};

describe("LocationResources", () => {
  it("links an item to its commodity and keeps where on the body it is", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        groups: [
          {
            kind: "ship_mineables",
            items: [
              {
                name: "Aluminum",
                note: null,
                commodity: { name: "Aluminum", slug: "aluminum" },
              },
            ],
          },
          {
            kind: "hand_mineables",
            items: [{ name: "Janalite", note: "Caves only", commodity: null }],
          },
        ],
      },
      plugins: [await router()],
    });

    expect(
      wrapper.find('a[href="#/catalogue/commodities/aluminum"]').text(),
    ).toBe("Aluminum");
    expect(wrapper.text()).toContain("Ship mineables");
    expect(wrapper.text()).toContain("Caves only");
  });
});
