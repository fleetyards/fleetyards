import { describe, expect, it, vi, beforeEach } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const claimKey = ref<{ key: string | null } | undefined>(undefined);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMySupporterClaimKey: () => ({ data: claimKey }),
  useSupportersProgress: () => ({ data: ref(undefined) }),
}));

const displaySuccess = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayAlert }),
}));

const setBackRoute = vi.fn();

vi.mock("@/shared/stores/redirectBack", () => ({
  useRedirectBackStore: () => ({ setBackRoute }),
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
    setBackRoute.mockClear();
    displaySuccess.mockClear();
    displayAlert.mockClear();
    Object.assign(navigator, { clipboard: { writeText } });
  });

  const mount = (props?: { standalone?: boolean }) =>
    mountWithDefaults(SupportContent, { props, plugins: [router] });

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

  // Claiming the key is why a signed-out visitor is sent to the login at all,
  // so the login has to come back to where they were about to donate.
  it("comes back to the page the modal was over after a login", async () => {
    authenticated.value = false;
    await router.push("/");

    const wrapper = await mount();
    await wrapper.find("[data-test='claim-key-signed-out']").trigger("click");

    expect(setBackRoute).toHaveBeenCalledWith({
      path: "/",
      query: { support: "true" },
      hash: "",
    });
  });

  // The page shows this content without a modal, so there is nothing to ask for
  // on the way back.
  it("comes back to the support page itself after a login", async () => {
    authenticated.value = false;

    const wrapper = await mount({ standalone: true });
    await wrapper.find("[data-test='claim-key-signed-out']").trigger("click");

    expect(setBackRoute).toHaveBeenCalledWith({
      name: "support",
    });
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

  // The key is in the field below, but only for somebody who thought to look:
  // every other copy in the app says when it failed, and this one has carried
  // the message for it all along.
  it("says so when the clipboard refuses", async () => {
    writeText.mockImplementationOnce(() => Promise.reject(new Error("nope")));

    const wrapper = await mount();
    await wrapper.find("[data-test='copy-claim-key']").trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
    expect(displaySuccess).not.toHaveBeenCalled();
  });

  it("says so when there is no clipboard at all", async () => {
    Object.assign(navigator, { clipboard: undefined });

    const wrapper = await mount();
    await wrapper.find("[data-test='copy-claim-key']").trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
  });

  it("copies nothing when signed out", async () => {
    authenticated.value = false;

    const wrapper = await mount();
    await wrapper.find("[data-test='support-paypal']").trigger("click");

    expect(writeText).not.toHaveBeenCalled();
  });
});
