import { describe, expect, it } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/support/", name: "support", component: { template: "<div />" } },
  ],
});

import SupportBtn from "./index.vue";

describe("SupportBtn", () => {
  it("links to the support page", async () => {
    const wrapper = await mountWithDefaults(SupportBtn, { plugins: [router] });

    expect(wrapper.get("a").attributes("href")).toBe("/support/");
  });
});
