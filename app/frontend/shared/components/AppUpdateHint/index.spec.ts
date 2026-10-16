import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { type VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

// A wrapper that is never unmounted leaves its pinia behind, and the next test
// then asserts against a second store and passes either way.
let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  vi.unstubAllGlobals();
});

const mount = async (whatsNewUrl: string) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { version: "v9.9.0", codename: "Ironclad", whatsNewUrl },
  });

  return wrapper;
};

describe("AppUpdateHint", () => {
  it("reloads the page", async () => {
    const reload = vi.fn();
    vi.stubGlobal("location", { ...window.location, reload });
    const subject = await mount("https://github.com/x");

    await subject.find("[data-test='app-update-reload']").trigger("click");

    expect(reload).toHaveBeenCalledOnce();
  });

  it("opens release notes outside the app in a new tab", async () => {
    const subject = await mount(
      "https://github.com/fleetyards/fleetyards/releases/tag/v9.9.0",
    );

    const link = subject.find("[data-test='app-update-whats-new']");

    expect(link.attributes("target")).toBe("_blank");
  });

  it("follows an announcement inside the app in place", async () => {
    const subject = await mount(`${window.location.origin}/fleets/`);

    const link = subject.find("[data-test='app-update-whats-new']");

    expect(link.attributes("target")).toBe("_self");
  });
});
