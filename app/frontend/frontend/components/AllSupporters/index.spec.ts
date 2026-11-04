import { describe, expect, it } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    {
      path: "/hangar/:username/",
      name: "hangar-public",
      component: { template: "<div />" },
    },
  ],
});

import AllSupporters from "./index.vue";

describe("AllSupporters", () => {
  it("links a supporter with a public hangar and leaves the rest as text", async () => {
    const wrapper = await mountWithDefaults(AllSupporters, {
      props: {
        supporters: [
          { displayName: "open", username: "open" },
          { displayName: "Dora" },
        ],
        anonymousCount: 0,
      },
      plugins: [router],
    });

    const items = wrapper.findAll(".all-supporters__item");

    expect(items[0]?.get("a").attributes("href")).toBe("/hangar/open/");
    expect(items[1]?.find("a").exists()).toBe(false);
    expect(items[1]?.text()).toBe("Dora");
    expect(wrapper.find("[data-test='anonymous-supporters']").exists()).toBe(
      false,
    );
  });

  it("sums up anonymous supporters in a single entry", async () => {
    const wrapper = await mountWithDefaults(AllSupporters, {
      props: { supporters: [{ displayName: "Dora" }], anonymousCount: 37 },
      plugins: [router],
    });

    expect(wrapper.findAll(".all-supporters__item")).toHaveLength(2);
    expect(wrapper.get("[data-test='anonymous-supporters']").text()).toContain(
      "37",
    );
  });
});
