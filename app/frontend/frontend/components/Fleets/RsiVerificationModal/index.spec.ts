import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
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

const mountPanel = (props: { fleet: Fleet }) =>
  mountWithDefaults(Component, { props });

describe("FleetRsiVerificationModal", () => {
  beforeEach(() => {
    verification.value = unverified();
    checkFleet.mockReset();
  });

  it("shows the token to put on the org page", async () => {
    const wrapper = await mountPanel({ fleet: fleet() });

    expect(
      wrapper.find('[data-test="fleet-rsi-verification-token"]').text(),
    ).toBe("FLEETYARDS-ABCDEFGHIJ");
  });

  it("asks for an SID before anything can be verified", async () => {
    verification.value = unverified({ sid: null, token: null });

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
});
