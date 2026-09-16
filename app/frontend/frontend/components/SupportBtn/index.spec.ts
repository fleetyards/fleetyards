import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const openModal = vi.fn();

vi.mock("@/frontend/composables/useModalQuery", () => ({
  useModalQuery: () => ({ openModal }),
}));

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/support/", name: "support", component: { template: "<div />" } },
  ],
});

import SupportBtn from "./index.vue";

describe("SupportBtn", () => {
  it("opens the support modal", async () => {
    const wrapper = await mountWithDefaults(SupportBtn, { plugins: [router] });

    await wrapper.find("button").trigger("click");

    expect(openModal).toHaveBeenCalledWith("support");
  });

  it("links to the support page instead when asked to", async () => {
    openModal.mockClear();

    const wrapper = await mountWithDefaults(SupportBtn, {
      props: { page: true },
      plugins: [router],
    });

    const link = wrapper.find("a");
    expect(link.attributes("href")).toBe("/support/");

    await link.trigger("click");

    expect(openModal).not.toHaveBeenCalled();
  });
});
