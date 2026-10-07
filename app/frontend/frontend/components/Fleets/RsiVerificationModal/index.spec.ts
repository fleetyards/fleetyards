import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { Fleet, FleetRsiVerification } from "@/services/fyApi";
import Component from "./index.vue";

const verification = ref<FleetRsiVerification | undefined>();
const checkFleet = vi.fn();

const mutation = (mutateAsync = vi.fn()) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetRsiVerification: () => ({ data: verification }),
    useCreateFleetRsiVerification: () => mutation(),
    useCheckFleetRsiVerification: () => mutation(checkFleet),
  };
});

const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

const extensionAnswers: Record<string, unknown> = {};
const extensionRequest = vi.fn(
  async (action: string, _params?: Record<string, unknown>) => {
    const answer = extensionAnswers[action];
    if (answer instanceof Error) throw answer;

    return answer;
  },
);
const extensionHealth = vi.fn(async (): Promise<unknown> => undefined);

vi.mock("@/frontend/composables/useSyncExtension", () => ({
  useSyncExtension: () => ({
    request: extensionRequest,
    health: extensionHealth,
  }),
}));

const fleet = (attributes: Partial<Fleet> = {}) =>
  ({
    slug: "test",
    fid: "TEST",
    rsiSid: "TEST",
    rsiVerified: false,
    ...attributes,
  }) as Fleet;

const unverified = (
  attributes: Partial<FleetRsiVerification> = {},
): FleetRsiVerification => ({
  sid: "TEST",
  token: "FLEETYARDS-ABCDEFGHIJ",
  status: null,
  verified: false,
  verifiedAt: null,
  checkedAt: null,
  ...attributes,
});

// Unmounted after each test: a modal left mounted keeps its watchers.
const mounted: { unmount: () => void }[] = [];

const mountPanel = async (props: { fleet: Fleet }) => {
  const wrapper = await mountWithDefaults(Component, { props });
  mounted.push(wrapper);

  return wrapper;
};

afterEach(() => {
  mounted.splice(0).forEach((wrapper) => {
    try {
      wrapper.unmount();
    } catch {
      // Already unmounted by the test.
    }
  });
});

describe("FleetRsiVerificationModal", () => {
  beforeEach(() => {
    verification.value = unverified();
    checkFleet.mockReset();
    displayAlert.mockClear();
    extensionRequest.mockClear();
    extensionHealth.mockReset().mockResolvedValue(undefined);
    Object.keys(extensionAnswers).forEach(
      (key) => delete extensionAnswers[key],
    );
  });

  it("shows the token to put on the org page", async () => {
    const wrapper = await mountPanel({ fleet: fleet() });

    expect(
      (
        wrapper.find('input[name="rsiVerificationToken"]')
          .element as HTMLInputElement
      ).value,
    ).toBe("FLEETYARDS-ABCDEFGHIJ");
  });

  it("offers no check without a SID", async () => {
    verification.value = unverified({ sid: null });

    const wrapper = await mountPanel({ fleet: fleet({ rsiSid: undefined }) });

    expect(
      wrapper.find('[data-test="fleet-rsi-verification-check"]').exists(),
    ).toBe(false);
  });

  it("holds the check back while the last one cools down", async () => {
    verification.value = unverified({
      status: "token_missing",
      nextCheckAt: new Date(Date.now() + 60_000).toISOString(),
    });

    const wrapper = await mountPanel({ fleet: fleet() });

    expect(
      wrapper
        .find('[data-test="fleet-rsi-verification-check"]')
        .attributes("disabled"),
    ).toBeDefined();
  });

  it("shows a verified fleet as verified", async () => {
    verification.value = unverified({ verified: true, status: "verified" });

    const wrapper = await mountPanel({ fleet: fleet({ rsiVerified: true }) });

    expect(wrapper.find('[data-test="fleet-rsi-verified"]').exists()).toBe(
      true,
    );
  });

  it("hides the check and a stale status once the fleet is verified", async () => {
    verification.value = unverified({
      verified: true,
      status: "token_missing",
    });

    const wrapper = await mountPanel({ fleet: fleet({ rsiVerified: true }) });

    expect(
      wrapper.find('[data-test="fleet-rsi-verification-check"]').exists(),
    ).toBe(false);
    expect(
      wrapper.find('[data-test="fleet-rsi-verification-status"]').exists(),
    ).toBe(false);
  });

  it("lets a check lost past its cooldown be started again", async () => {
    verification.value = unverified({
      status: "pending",
      nextCheckAt: new Date(Date.now() - 1_000).toISOString(),
    });

    const wrapper = await mountPanel({ fleet: fleet() });

    expect(
      wrapper
        .find('[data-test="fleet-rsi-verification-check"]')
        .attributes("disabled"),
    ).toBeUndefined();
  });

  describe("with the sync extension", () => {
    const signedIn = () => {
      extensionHealth.mockResolvedValue({
        code: 200,
        payload: {
          version: "1.4.0",
          actions: ["health", "identify", "org-verify-write"],
        },
      });
      extensionAnswers.identify = { code: 200, payload: { handle: "Officer" } };
      extensionAnswers["org-verify-remove"] = { code: 200 };
    };

    const writes = (
      answer: unknown = { code: 200, payload: { sid: "TEST", changed: true } },
    ) => {
      extensionAnswers["org-verify-write"] = answer;
    };

    const checkStartsJob = () =>
      checkFleet.mockImplementation(async () => {
        verification.value = unverified({
          status: "pending",
          nextCheckAt: new Date(Date.now() + 60_000).toISOString(),
        });

        return verification.value;
      });

    const verifyButton = (wrapper: Awaited<ReturnType<typeof mountPanel>>) =>
      wrapper.find('[data-test="fleet-rsi-verification-extension-verify"]');

    const removals = () =>
      extensionRequest.mock.calls.filter(
        ([action]) => action === "org-verify-remove",
      );

    it("offers the extension's store links without one", async () => {
      const wrapper = await mountPanel({ fleet: fleet() });
      await flushPromises();

      expect(
        wrapper
          .find('[data-test="fleet-rsi-verification-extension-install"]')
          .text(),
      ).toContain("Install");
      expect(verifyButton(wrapper).exists()).toBe(false);
    });

    it("writes the token to the org, checks, and takes it out once answered", async () => {
      signedIn();
      writes();
      checkStartsJob();

      const wrapper = await mountPanel({ fleet: fleet() });
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();

      expect(extensionRequest).toHaveBeenCalledWith("org-verify-write", {
        sid: "TEST",
        token: "FLEETYARDS-ABCDEFGHIJ",
      });
      expect(checkFleet).toHaveBeenCalled();
      expect(removals()).toHaveLength(0);

      verification.value = unverified({ status: "token_missing" });
      await flushPromises();

      expect(removals()).toEqual([
        ["org-verify-remove", { sid: "TEST", token: "FLEETYARDS-ABCDEFGHIJ" }],
      ]);
    });

    it.each([
      [403, "cannot edit"],
      [409, "unpublished changes"],
      [422, "could not read"],
    ])(
      "explains a %s from the extension without checking",
      async (code, text) => {
        signedIn();
        writes({ code, payload: { sid: "TEST" } });

        const wrapper = await mountPanel({ fleet: fleet() });
        await flushPromises();
        await verifyButton(wrapper).trigger("click");
        await flushPromises();

        const error = wrapper.find(
          '[data-test="fleet-rsi-verification-extension-error"]',
        );
        expect(error.text()).toContain(text);
        expect(error.text()).toContain("TEST");
        expect(checkFleet).not.toHaveBeenCalled();
      },
    );

    it("takes the token out when the modal closes mid-check", async () => {
      signedIn();
      writes();
      checkStartsJob();

      const wrapper = await mountPanel({ fleet: fleet() });
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();
      wrapper.unmount();

      expect(removals()).toHaveLength(1);
    });

    it("removes from the org it wrote to, whatever the modal shows now", async () => {
      signedIn();
      writes();
      checkStartsJob();

      const wrapper = await mountPanel({ fleet: fleet() });
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();

      verification.value = unverified({
        sid: "OTHER",
        status: "token_missing",
      });
      await flushPromises();

      expect(removals()).toEqual([
        ["org-verify-remove", { sid: "TEST", token: "FLEETYARDS-ABCDEFGHIJ" }],
      ]);
    });

    it("takes an older token out before writing a regenerated one", async () => {
      signedIn();
      extensionAnswers["org-verify-write"] = new Error("no answer");

      const wrapper = await mountPanel({ fleet: fleet() });
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();

      verification.value = unverified({ token: "FLEETYARDS-NEWTOKEN00" });
      writes();
      checkStartsJob();
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();

      const calls = extensionRequest.mock.calls.filter(([action]) =>
        String(action).startsWith("org-verify"),
      );
      expect(calls.slice(1, 3)).toEqual([
        ["org-verify-remove", { sid: "TEST", token: "FLEETYARDS-ABCDEFGHIJ" }],
        ["org-verify-write", { sid: "TEST", token: "FLEETYARDS-NEWTOKEN00" }],
      ]);
    });

    it("shows the check's result next to the extension", async () => {
      signedIn();
      writes();
      checkStartsJob();

      const wrapper = await mountPanel({ fleet: fleet() });
      await flushPromises();
      await verifyButton(wrapper).trigger("click");
      await flushPromises();

      verification.value = unverified({
        status: "token_missing",
        nextCheckAt: new Date(Date.now() + 60_000).toISOString(),
      });
      await flushPromises();

      expect(
        wrapper
          .find('[data-test="fleet-rsi-verification-extension-status"]')
          .exists(),
      ).toBe(true);
      expect(
        wrapper.find('[data-test="fleet-rsi-verification-status"]').exists(),
      ).toBe(false);
    });
  });
});
