import { describe, expect, it, vi, beforeEach } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const claimKey = ref<{ key: string | null } | undefined>(undefined);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMySupporterClaimKey: () => ({ data: claimKey }),
  useSupportersProgress: () => ({ data: ref(undefined) }),
}));

const authenticated = ref(true);

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/login", name: "login", component: { template: "<div />" } },
  ],
});

import SupportContent from "./index.vue";

const writeText = vi.fn(() => Promise.resolve());

describe("SupportContent", () => {
  beforeEach(() => {
    claimKey.value = { key: "FY-7K2M-9QXD" };
    authenticated.value = true;
    writeText.mockClear();
    Object.assign(navigator, { clipboard: { writeText } });
  });

  const mount = () => mountWithDefaults(SupportContent, { plugins: [router] });

  it("shows the key to a signed-in supporter", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='claim-key']").exists()).toBe(true);
    expect(wrapper.find("[data-test='copy-claim-key']").exists()).toBe(true);
  });

  it("points a signed-out visitor at the login instead of the key", async () => {
    authenticated.value = false;
    claimKey.value = undefined;

    const wrapper = await mount();

    expect(wrapper.find("[data-test='claim-key']").exists()).toBe(false);
    expect(wrapper.find("[data-test='copy-claim-key']").exists()).toBe(false);
    expect(
      wrapper.find("[data-test='claim-key-signed-out']").attributes("href"),
    ).toBe("/login");
  });

  // The query is only disabled on logout, not cleared -- it keeps serving the
  // key it fetched for the person who just left.
  it("hides a key left in the cache after a logout", async () => {
    authenticated.value = false;

    const wrapper = await mount();

    expect(wrapper.find("[data-test='claim-key']").exists()).toBe(false);
    expect(wrapper.find("[data-test='claim-key-signed-out']").exists()).toBe(
      true,
    );
  });

  it("shows no signed-out hint to a signed-in supporter", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='claim-key-signed-out']").exists()).toBe(
      false,
    );
  });

  // Ko-fi has no URL parameter to prefill a message with, so the key goes to
  // the clipboard on the way out instead.
  it.each(["paypal", "kofi", "bmac"])(
    "copies the key when opening %s",
    async (platform) => {
      const wrapper = await mount();

      await wrapper.find(`[data-test='support-${platform}']`).trigger("click");

      expect(writeText).toHaveBeenCalledWith("FY-7K2M-9QXD");
    },
  );

  it("copies the key from the copy button", async () => {
    const wrapper = await mount();

    await wrapper.find("[data-test='copy-claim-key']").trigger("click");

    expect(writeText).toHaveBeenCalledWith("FY-7K2M-9QXD");
  });

  // Patreon carries no donor message, so a key would be copied for nothing and
  // read as something the donor is meant to paste somewhere.
  it("does not copy the key when opening Patreon", async () => {
    const wrapper = await mount();

    await wrapper.find("[data-test='support-patreon']").trigger("click");

    expect(writeText).not.toHaveBeenCalled();
  });

  it("copies nothing when signed out", async () => {
    authenticated.value = false;

    const wrapper = await mount();
    await wrapper.find("[data-test='support-paypal']").trigger("click");

    expect(writeText).not.toHaveBeenCalled();
  });
});
