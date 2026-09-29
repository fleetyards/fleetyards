import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { useVerifiedOrgLabel } from "./useVerifiedOrgLabel";

describe("useVerifiedOrgLabel", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("keeps the age current while the tooltip stays open", async () => {
    vi.useFakeTimers();
    const label = useVerifiedOrgLabel();
    const member = {
      verifiedOrgSid: "MARU",
      verificationCheckedAt: new Date(Date.now() - 3 * 3600_000).toISOString(),
    };
    const shown = computed(() => label(member));

    expect(shown.value).toMatch(/3 hours ago/);

    await vi.advanceTimersByTimeAsync(2 * 3600_000);

    expect(shown.value).toMatch(/5 hours ago/);
  });

  it("says when RSI was last asked", () => {
    const label = useVerifiedOrgLabel();

    expect(
      label({
        verifiedOrgSid: "MARU",
        verificationCheckedAt: new Date(
          Date.now() - 3 * 3600_000,
        ).toISOString(),
      }),
    ).toMatch(/MARU.*3 hours ago/);
  });

  it("names the org alone without a check time, and nothing without an org", () => {
    const label = useVerifiedOrgLabel();

    expect(label({ verifiedOrgSid: "MARU" })).toBe("Verified member of MARU");
    expect(label({})).toBeUndefined();
  });
});
