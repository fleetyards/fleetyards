import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type {
  Fleet,
  FleetFidClaim,
  FleetFidClaimStatus,
} from "@/services/fyApi";
import Component from "./index.vue";

const claimStatus = ref<FleetFidClaimStatus | undefined>();

const createClaim = vi.fn();

const withdrawClaim = vi.fn();

const mutation = (mutateAsync: ReturnType<typeof vi.fn>) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetFidClaim: () => ({ data: claimStatus, refetch: vi.fn() }),
    useCreateFleetFidClaim: () => mutation(createClaim),
    useDestroyFleetFidClaim: () => mutation(withdrawClaim),
  };
});

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
    displayConfirm: ({ onConfirm }: { onConfirm: () => void }) => onConfirm(),
  }),
}));

const fleet = { slug: "test-1", fid: "TEST-1", rsiVerified: true } as Fleet;

const openClaim: FleetFidClaim = {
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
};

const mountPanel = () => mountWithDefaults(Component, { props: { fleet } });

describe("FleetFidClaimPanel", () => {
  beforeEach(() => {
    createClaim.mockReset();
    withdrawClaim.mockReset();
  });

  it("offers the claim when another fleet holds the verified SID", async () => {
    claimStatus.value = { availability: "claimable", fid: "TEST" };
    createClaim.mockResolvedValue({
      availability: "pending",
      fid: "TEST",
      outgoing: openClaim,
    });
    const wrapper = await mountPanel();

    await wrapper.find('[data-test="fleet-fid-claim-create"]').trigger("click");
    await flushPromises();

    expect(createClaim).toHaveBeenCalledWith({ fleetSlug: "test-1" });
  });

  it("shows an open claim and lets it be withdrawn", async () => {
    claimStatus.value = {
      availability: "pending",
      fid: "TEST",
      outgoing: openClaim,
    };
    withdrawClaim.mockResolvedValue({ availability: "claimable", fid: "TEST" });
    const wrapper = await mountPanel();

    expect(
      wrapper.find('[data-test="fleet-fid-claim-pending"]').text(),
    ).toContain("Squatters");

    await wrapper
      .find('[data-test="fleet-fid-claim-withdraw"]')
      .trigger("click");
    await flushPromises();

    expect(withdrawClaim).toHaveBeenCalledWith({ fleetSlug: "test-1" });
  });

  it("points to the form when nobody holds the FID", async () => {
    claimStatus.value = { availability: "available", fid: "TEST" };
    const wrapper = await mountPanel();

    expect(
      wrapper.find('[data-test="fleet-fid-claim-available"]').exists(),
    ).toBe(true);
    expect(wrapper.find('[data-test="fleet-fid-claim-create"]').exists()).toBe(
      false,
    );
  });

  it("shows nothing to a fleet that cannot claim", async () => {
    claimStatus.value = { availability: "unverified", fid: null };
    const wrapper = await mountPanel();

    expect(wrapper.text()).toBe("");
  });
});
