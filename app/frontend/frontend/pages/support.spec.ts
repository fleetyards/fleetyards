import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const supporters = vi.hoisted(() => ({ value: undefined as unknown }));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMySupporterClaimKey: () => ({ data: ref(undefined) }),
  useSupportersProgress: () => ({ data: ref(undefined) }),
  useSupporters: () => ({ data: ref(supporters.value) }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({ isAuthenticated: false }),
}));

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/login", name: "login", component: { template: "<div />" } },
  ],
});

import SupportPage from "./support.vue";

// The page exists so a post can link somewhere; what it has to show is the
// same thing the footer's modal shows.
describe("SupportPage", () => {
  it("shows the support content", async () => {
    const wrapper = await mountWithDefaults(SupportPage, {
      plugins: [router],
    });

    expect(wrapper.findComponent({ name: "SupportContent" }).exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='support-kofi']").exists()).toBe(true);
  });

  it("shows nothing for the full list until somebody is on it", async () => {
    supporters.value = { supporters: [], anonymousCount: 0 };

    const wrapper = await mountWithDefaults(SupportPage, {
      plugins: [router],
    });

    expect(wrapper.find("[data-test='all-supporters']").exists()).toBe(false);
  });

  it("lists every supporter", async () => {
    supporters.value = {
      supporters: [{ displayName: "Alice" }],
      anonymousCount: 0,
    };

    const wrapper = await mountWithDefaults(SupportPage, {
      plugins: [router],
    });

    expect(wrapper.get("[data-test='all-supporters']").text()).toContain(
      "Alice",
    );
  });

  it("shows the panel when every supporter is anonymous", async () => {
    supporters.value = { supporters: [], anonymousCount: 2 };

    const wrapper = await mountWithDefaults(SupportPage, {
      plugins: [router],
    });

    expect(wrapper.find("[data-test='anonymous-supporters']").exists()).toBe(
      true,
    );
  });
});
