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

// Signed out, the content offers the login link, so the route has to exist.
const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/login", name: "login", component: { template: "<div />" } },
  ],
});

import SupportModal from "./index.vue";

// The platforms, the key and the copying are covered where they live, in
// SupportContent. What is left here is the wrapping: the modal is one of two
// places that content is shown, and the other is the support page.
describe("SupportModal", () => {
  it("shows the support content in a modal", async () => {
    const wrapper = await mountWithDefaults(SupportModal, {
      plugins: [router],
    });

    expect(wrapper.findComponent({ name: "SupportContent" }).exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='support-paypal']").exists()).toBe(true);
  });
});
