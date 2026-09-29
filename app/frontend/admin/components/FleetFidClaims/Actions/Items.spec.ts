import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { AdminFleetFidClaim } from "@/services/fyAdminApi";
import Component from "./Items.vue";

const {
  updateClaim,
  cancelClaim,
  invalidateQueries,
  displaySuccess,
  displayAlert,
} = vi.hoisted(() => ({
  updateClaim: vi.fn(),
  cancelClaim: vi.fn(),
  invalidateQueries: vi.fn(),
  displaySuccess: vi.fn(),
  displayAlert: vi.fn(),
}));

let confirmed: string[] = [];

vi.mock("@tanstack/vue-query", async () => {
  const actual = await vi.importActual<Record<string, unknown>>(
    "@tanstack/vue-query",
  );

  return { ...actual, useQueryClient: () => ({ invalidateQueries }) };
});

vi.mock("@/services/fyAdminApi", async () => {
  const actual = await vi.importActual<Record<string, unknown>>(
    "@/services/fyAdminApi",
  );

  const mutation =
    (mutateAsync: (...args: unknown[]) => unknown) =>
    (options?: { mutation?: { onSettled?: () => void } }) => ({
      mutateAsync: (...args: unknown[]) =>
        Promise.resolve(mutateAsync(...args)).finally(() =>
          options?.mutation?.onSettled?.(),
        ),
      isPending: ref(false),
    });

  return {
    ...actual,
    useUpdateFleetFidClaim: mutation(updateClaim),
    useCancelFleetFidClaim: mutation(cancelClaim),
  };
});

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess,
    displayAlert,
    displayConfirm: ({
      text,
      onConfirm,
    }: {
      text: string;
      onConfirm: () => void;
    }) => {
      confirmed.push(text);
      onConfirm();
    },
  }),
}));

const claim: AdminFleetFidClaim = {
  id: "d6c5a6b0-2f53-4f3c-9d0f-5d8f1a6c1a11",
  fid: "MARU",
  state: "open",
  cancelReason: null,
  endsAt: "2026-10-13T12:00:00Z",
  claimantId: "c1",
  claimantName: "Maru",
  claimantFid: "MARU-1",
  holderId: "h1",
  holderName: "MARU Inc.",
  holderFid: "maru",
  holderNewFid: null,
  completedAt: null,
  cancelledAt: null,
  createdAt: "2026-09-29T12:00:00Z",
};

const mountItems = () =>
  mountWithDefaults(Component, { props: { claim, withLabels: true } });

describe("FleetFidClaimActionItems", () => {
  beforeEach(() => {
    confirmed = [];
    [
      updateClaim,
      cancelClaim,
      invalidateQueries,
      displaySuccess,
      displayAlert,
    ].forEach((mock) => mock.mockReset());
  });

  it("ends the grace period now after a confirmation", async () => {
    updateClaim.mockResolvedValue({ ...claim, state: "completed" });
    const wrapper = await mountItems();

    await wrapper
      .find('[data-test="fleet-fid-claim-end-now"]')
      .trigger("click");
    await flushPromises();

    expect(confirmed).toHaveLength(1);
    expect(updateClaim).toHaveBeenCalledWith({
      id: claim.id,
      data: { endsAt: expect.any(String) },
    });
    expect(displaySuccess).toHaveBeenCalled();
    expect(invalidateQueries).toHaveBeenCalled();
  });

  it("reports an end-now the server refused", async () => {
    updateClaim.mockRejectedValue(new Error("refused"));
    const wrapper = await mountItems();

    await wrapper
      .find('[data-test="fleet-fid-claim-end-now"]')
      .trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
    expect(displaySuccess).not.toHaveBeenCalled();
  });

  it("cancels the claim after a confirmation", async () => {
    cancelClaim.mockResolvedValue({ ...claim, state: "cancelled" });
    const wrapper = await mountItems();

    await wrapper.find('[data-test="fleet-fid-claim-cancel"]').trigger("click");
    await flushPromises();

    expect(confirmed).toHaveLength(1);
    expect(cancelClaim).toHaveBeenCalledWith({ id: claim.id });
    expect(invalidateQueries).toHaveBeenCalled();
  });
});
