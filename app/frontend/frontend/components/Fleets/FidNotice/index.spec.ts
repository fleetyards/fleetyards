import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { Fleet, FleetFidClaimStatus } from "@/services/fyApi";
import Component from "./index.vue";

const claimStatus = ref<FleetFidClaimStatus | undefined>();

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return { ...actual, useFleetFidClaim: () => ({ data: claimStatus }) };
});

const fleet = (attributes: Partial<Fleet> = {}) =>
  ({ slug: "test", fid: "test", rsiVerified: false, ...attributes }) as Fleet;

const mountNotice = (props: { fleet: Fleet }) =>
  mountWithDefaults(Component, { props });

describe("FleetFidNotice", () => {
  it("warns a holder whose FID another fleet claims", async () => {
    claimStatus.value = {
      availability: "unverified",
      fid: null,
      incoming: {
        id: "d6c5a6b0-2f53-4f3c-9d0f-5d8f1a6c1a11",
        fid: "TEST",
        state: "open",
        cancelReason: null,
        endsAt: "2026-10-13T12:00:00Z",
        claimantName: "Real Org",
        claimantFid: "TEST-1",
        holderName: "Squatters",
        holderFid: "test",
        createdAt: "2026-09-29T12:00:00Z",
      },
    };
    const wrapper = await mountNotice({ fleet: fleet() });

    expect(
      wrapper.find('[data-test="fleet-fid-claim-incoming"]').text(),
    ).toContain("Real Org");
    // The date, what happens on it and how to keep the ID, as a list.
    expect(
      wrapper.findAll('[data-test="fleet-fid-claim-incoming"] li'),
    ).toHaveLength(2);
    expect(wrapper.find('[data-test="fleet-fid-at-risk"]').exists()).toBe(
      false,
    );
  });

  it("falls back to the at-risk warning without a claim", async () => {
    claimStatus.value = { availability: "unverified", fid: null };
    const wrapper = await mountNotice({ fleet: fleet() });

    expect(wrapper.find('[data-test="fleet-fid-at-risk"]').exists()).toBe(true);
  });

  it("says nothing to a fleet verified for its own FID", async () => {
    claimStatus.value = { availability: "held", fid: "TEST" };
    const wrapper = await mountNotice({
      fleet: fleet({ rsiVerified: true, rsiSid: "TEST" }),
    });

    expect(wrapper.text()).toBe("");
  });
});
