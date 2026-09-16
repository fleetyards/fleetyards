import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMySupporterClaimKey: () => ({ data: ref(undefined) }),
  useSupportersProgress: () => ({ data: ref(undefined) }),
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
});
