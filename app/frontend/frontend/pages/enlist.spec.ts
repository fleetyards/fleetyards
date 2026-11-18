import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  RSI_ENLIST_URL,
  RSI_REFERRAL_CODE,
} from "@/frontend/utils/rsiReferral";

const displaySuccess = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayAlert }),
}));

import EnlistPage from "./enlist.vue";

describe("EnlistPage", () => {
  beforeEach(() => {
    displaySuccess.mockClear();
    displayAlert.mockClear();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  const stubClipboard = (clipboard?: Partial<Clipboard>) => {
    vi.stubGlobal("navigator", { ...navigator, clipboard });
  };

  it("shows the code and links to RSI's sign-up with it", async () => {
    const wrapper = await mountWithDefaults(EnlistPage);

    expect(wrapper.get("[data-test='enlist-code']").text()).toBe(
      RSI_REFERRAL_CODE,
    );
    expect(wrapper.get("[data-test='enlist-sign-up']").attributes("href")).toBe(
      RSI_ENLIST_URL,
    );
  });

  it("copies the code", async () => {
    const writeText = vi.fn(() => Promise.resolve());
    stubClipboard({ writeText });

    const wrapper = await mountWithDefaults(EnlistPage);
    await wrapper.get("[data-test='enlist-copy']").trigger("click");
    await flushPromises();

    expect(writeText).toHaveBeenCalledWith(RSI_REFERRAL_CODE);
    expect(displaySuccess).toHaveBeenCalled();
  });

  it("says so when the browser has no clipboard", async () => {
    stubClipboard(undefined);

    const wrapper = await mountWithDefaults(EnlistPage);
    await wrapper.get("[data-test='enlist-copy']").trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
  });
});
