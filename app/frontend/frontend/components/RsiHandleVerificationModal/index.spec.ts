import { flushPromises } from "@vue/test-utils";
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

const extensionAnswers: Record<string, unknown> = {};
const extensionRequest = vi.fn(
  async (action: string, _params?: Record<string, unknown>) => {
    const answer = extensionAnswers[action];
    if (answer instanceof Error) throw answer;

    return answer;
  },
);
const extensionSupports = vi.fn(async () => false);

vi.mock("@/frontend/composables/useSyncExtension", () => ({
  useSyncExtension: () => ({
    request: extensionRequest,
    supports: extensionSupports,
  }),
}));

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
    extensionRequest.mockClear();
    extensionSupports.mockReset().mockResolvedValue(false);
    Object.keys(extensionAnswers).forEach(
      (key) => delete extensionAnswers[key],
    );
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

  describe("with the sync extension", () => {
    const signedInAs = (handle: string) => {
      extensionSupports.mockResolvedValue(true);
      extensionAnswers.identify = { code: 200, payload: { handle } };
    };

    const removals = () =>
      extensionRequest.mock.calls.filter(
        ([action]) => action === "verify-remove",
      );

    // The check starts a job: the modal waits for it while the status reads
    // pending inside the cooldown, the way the endpoint answers.
    const checkStartsJob = () =>
      checkHandle.mockImplementation(async () => {
        verification.value = unverified({
          status: "pending",
          nextCheckAt: new Date(Date.now() + 60_000).toISOString(),
        });

        return verification.value;
      });

    const extensionBlock = (wrapper: Awaited<ReturnType<typeof mountModal>>) =>
      wrapper.find('[data-test="user-rsi-verification-extension"]');

    const verifyButton = (wrapper: Awaited<ReturnType<typeof mountModal>>) =>
      wrapper.find('[data-test="user-rsi-verification-extension-verify"]');

    it("offers nothing without an extension that can verify", async () => {
      const wrapper = await mountModal();
      await flushPromises();

      expect(extensionBlock(wrapper).exists()).toBe(false);
      expect(extensionRequest).not.toHaveBeenCalled();
    });

    it("explains a browser signed in to a different handle", async () => {
      signedInAs("SomeoneElse");

      const wrapper = await mountModal();
      await flushPromises();

      const mismatch = wrapper.find(
        '[data-test="user-rsi-verification-extension-mismatch"]',
      );
      expect(mismatch.text()).toContain("SomeoneElse");
      expect(mismatch.text()).toContain("TestPilot");
      expect(verifyButton(wrapper).exists()).toBe(false);
    });

    it("asks for an RSI sign-in without one", async () => {
      extensionSupports.mockResolvedValue(true);
      extensionAnswers.identify = { code: 400 };

      const wrapper = await mountModal();
      await flushPromises();

      expect(
        wrapper
          .find('[data-test="user-rsi-verification-extension-signed-out"]')
          .exists(),
      ).toBe(true);
      expect(verifyButton(wrapper).exists()).toBe(false);
    });

    it("matches the signed-in handle in any case", async () => {
      signedInAs("testpilot");

      const wrapper = await mountModal();
      await flushPromises();

      expect(verifyButton(wrapper).exists()).toBe(true);
    });

    it("writes the token, checks, and takes the token out once answered", async () => {
      signedInAs("TestPilot");
      extensionAnswers["verify-write"] = {
        code: 200,
        payload: { handle: "TestPilot", changed: true },
      };
      checkStartsJob();

      const wrapper = await mountModal();
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();

      expect(extensionRequest).toHaveBeenCalledWith("verify-write", {
        token: "FLEETYARDS-ABCDEFGHIJ",
      });
      expect(checkHandle).toHaveBeenCalled();
      expect(removals()).toHaveLength(0);

      verification.value = unverified({ status: "token_missing" });
      await flushPromises();

      expect(removals()).toEqual([
        ["verify-remove", { token: "FLEETYARDS-ABCDEFGHIJ" }],
      ]);
    });

    it("leaves a token it did not add", async () => {
      signedInAs("TestPilot");
      extensionAnswers["verify-write"] = {
        code: 200,
        payload: { handle: "TestPilot", changed: false },
      };
      checkStartsJob();

      const wrapper = await mountModal();
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();

      verification.value = unverified({ status: "token_missing" });
      await flushPromises();
      wrapper.unmount();

      expect(removals()).toHaveLength(0);
    });

    it("takes the token out when the modal closes mid-check", async () => {
      signedInAs("TestPilot");
      extensionAnswers["verify-write"] = {
        code: 200,
        payload: { handle: "TestPilot", changed: true },
      };
      checkStartsJob();

      const wrapper = await mountModal();
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();
      wrapper.unmount();

      expect(removals()).toHaveLength(1);
    });

    it.each([
      [413, "too long"],
      [422, "formatting"],
      [500, "could not update"],
    ])(
      "explains a %s from the extension without checking",
      async (code, text) => {
        signedInAs("TestPilot");
        extensionAnswers["verify-write"] = { code };

        const wrapper = await mountModal();
        await flushPromises();
        await verifyButton(wrapper).trigger("click");
        await flushPromises();

        expect(
          wrapper
            .find('[data-test="user-rsi-verification-extension-error"]')
            .text(),
        ).toContain(text);
        expect(checkHandle).not.toHaveBeenCalled();
      },
    );
  });
});
