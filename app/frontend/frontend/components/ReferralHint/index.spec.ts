import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import ReferralHint from "./index.vue";
import {
  RSI_ENLIST_URL,
  RSI_REFERRAL_CODE,
} from "@/frontend/utils/rsiReferral";

describe("ReferralHint", () => {
  it("links the code to RSI's sign-up with the code filled in", async () => {
    const wrapper = await mountWithDefaults(ReferralHint);
    const link = wrapper.get("[data-test='referral-hint-code']");

    expect(link.text()).toBe(RSI_REFERRAL_CODE);
    expect(link.attributes("href")).toBe(RSI_ENLIST_URL);
    expect(RSI_ENLIST_URL).toContain(`referral=${RSI_REFERRAL_CODE}`);
  });
});
