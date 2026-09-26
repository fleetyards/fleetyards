import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { ref } from "vue";
import Component from "./index.vue";

const install = vi.fn();
const canInstall = ref(true);
const hideMessage = vi.fn();

vi.mock("@/shared/stores/notifications", () => ({
  useNotificationsStore: () => ({ hideMessage }),
}));

vi.mock("@/frontend/composables/useInstallPrompt", () => ({
  useInstallPrompt: () => ({ install, canInstall }),
}));

// A wrapper that is never unmounted leaves its pinia behind, and the next test
// then asserts against a second store and passes either way.
let wrapper: VueWrapper | undefined;

beforeEach(() => {
  install.mockReset();
  hideMessage.mockReset();
  canInstall.value = true;
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { context: "eventSignup", notificationId: "offer-1" },
  });

  return wrapper;
};

describe("InstallAppHint", () => {
  it("installs and takes the offer down", async () => {
    const subject = await mount();

    await subject.find("[data-test='install-app-hint-cta']").trigger("click");

    expect(install).toHaveBeenCalledOnce();
    expect(hideMessage).toHaveBeenCalledWith("offer-1");
  });

  it("steps aside without installing", async () => {
    const subject = await mount();

    await subject.find("[data-test='install-app-hint-later']").trigger("click");

    expect(install).not.toHaveBeenCalled();
    expect(hideMessage).toHaveBeenCalledWith("offer-1");
  });

  it("closes itself once installing is no longer possible", async () => {
    await mount();

    canInstall.value = false;
    await wrapper?.vm.$nextTick();

    expect(hideMessage).toHaveBeenCalledWith("offer-1");
  });
});
