import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { UserRsiVerification } from "@/services/fyApi";
import Component from "./index.vue";

const verification = ref<UserRsiVerification | undefined>();
const checkHandle = vi.fn();

const mutation = (mutateAsync = vi.fn()) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useMyRsiVerification: () => ({ data: verification }),
    useCreateMyRsiVerification: () => mutation(),
    useCheckMyRsiVerification: () => mutation(checkHandle),
  };
});

const unverified = (
  attributes: Partial<UserRsiVerification> = {},
): UserRsiVerification => ({
  handle: "TestPilot",
  token: "FLEETYARDS-ABCDEFGHIJ",
  status: null,
  verified: false,
  verifiedVia: null,
  verifiedAt: null,
  checkedAt: null,
  ...attributes,
});

const mountModal = () => mountWithDefaults(Component);

describe("RsiHandleVerificationModal", () => {
  beforeEach(() => {
    verification.value = unverified();
    checkHandle.mockReset();
  });

  it("shows the token to put in the bio", async () => {
    const wrapper = await mountModal();

    expect(
      (
        wrapper.find('input[name="rsiVerificationToken"]')
          .element as HTMLInputElement
      ).value,
    ).toBe("FLEETYARDS-ABCDEFGHIJ");
  });

  it("offers no check without a saved handle", async () => {
    verification.value = unverified({ handle: null });

    const wrapper = await mountModal();

    expect(
      wrapper.find('[data-test="user-rsi-verification-check"]').exists(),
    ).toBe(false);
  });

  it("holds the check back while the last one cools down", async () => {
    verification.value = unverified({
      status: "token_missing",
      nextCheckAt: new Date(Date.now() + 60_000).toISOString(),
    });

    const wrapper = await mountModal();

    expect(
      wrapper
        .find('[data-test="user-rsi-verification-check"]')
        .attributes("disabled"),
    ).toBeDefined();
  });

  it("counts the cooldown down on the check and offers it again after", async () => {
    vi.useFakeTimers();
    try {
      verification.value = unverified({
        status: "token_missing",
        nextCheckAt: new Date(Date.now() + 42_000).toISOString(),
      });

      const wrapper = await mountModal();
      const button = () =>
        wrapper.find('[data-test="user-rsi-verification-check"]');

      expect(button().attributes("disabled")).toBeDefined();
      expect(button().text()).toContain("42");

      await vi.advanceTimersByTimeAsync(43_000);

      expect(button().attributes("disabled")).toBeUndefined();
      expect(button().text()).not.toContain("42");
    } finally {
      vi.useRealTimers();
    }
  });

  it("shows a verified handle as verified, with nothing to remove", async () => {
    verification.value = unverified({
      verified: true,
      verifiedVia: "rsi_profile",
      status: "verified",
    });

    const wrapper = await mountModal();

    expect(wrapper.find('[data-test="user-rsi-verified"]').exists()).toBe(true);
    expect(
      wrapper.find('[data-test="user-rsi-verification-check"]').exists(),
    ).toBe(false);
    expect(
      wrapper.find('[data-test="user-rsi-verification-remove"]').exists(),
    ).toBe(false);
  });
});
