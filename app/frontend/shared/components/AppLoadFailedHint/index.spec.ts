import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { type VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  vi.unstubAllGlobals();
});

describe("AppLoadFailedHint", () => {
  it("reloads the page", async () => {
    const reload = vi.fn();
    vi.stubGlobal("location", { ...window.location, reload });
    wrapper = await mountWithDefaults<typeof Component>(Component);

    await wrapper.find("[data-test='app-load-failed-reload']").trigger("click");

    expect(reload).toHaveBeenCalledTimes(1);
  });
});
