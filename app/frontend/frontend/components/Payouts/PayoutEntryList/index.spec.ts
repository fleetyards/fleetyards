import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import Component from "./index.vue";
import {
  PayoutEntryReviewStatusEnum,
  PayoutEntryTypeEnum,
  type PayoutEntry,
} from "@/services/fyApi";

const entry = (overrides: Partial<PayoutEntry> = {}): PayoutEntry =>
  ({
    id: "entry-1",
    payoutLedgerId: "ledger-1",
    payoutParticipantId: "participant-1",
    entryType: PayoutEntryTypeEnum.EXPENSE,
    reviewStatus: PayoutEntryReviewStatusEnum.PENDING,
    amount: "1200",
    description: "Refuel",
    participant: {
      id: "participant-1",
      payoutLedgerId: "ledger-1",
      displayName: "Mal",
      guest: false,
      weight: "1.0",
    },
    ...overrides,
  }) as PayoutEntry;

const wrappers: Array<{ unmount: () => void }> = [];

const mount = async (props: {
  entries: PayoutEntry[];
  reviewable?: boolean;
}) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { payoutLedgerId: "ledger-1", participants: [], ...props },
  });
  wrappers.push(wrapper);
  return wrapper;
};

afterEach(() => {
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }
});

describe("PayoutEntryList", () => {
  it("offers a manager both answers on a pending expense", async () => {
    const wrapper = await mount({ entries: [entry()], reviewable: true });

    expect(wrapper.find('[data-test="payout-entry-approve"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="payout-entry-decline"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="payout-entry-review"]').exists()).toBe(
      true,
    );
  });

  it("offers no answers to somebody who cannot review", async () => {
    const wrapper = await mount({ entries: [entry()] });

    expect(wrapper.find('[data-test="payout-entry-approve"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="payout-entry-review"]').exists()).toBe(
      true,
    );
  });

  it("marks nothing on an approved entry", async () => {
    const wrapper = await mount({
      entries: [entry({ reviewStatus: PayoutEntryReviewStatusEnum.APPROVED })],
      reviewable: true,
    });

    expect(wrapper.find('[data-test="payout-entry-review"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="payout-entry-approve"]').exists()).toBe(
      false,
    );
  });

  it("shows why an expense was declined", async () => {
    const wrapper = await mount({
      entries: [
        entry({
          reviewStatus: PayoutEntryReviewStatusEnum.DECLINED,
          declineReason: "No receipt",
        }),
      ],
    });

    expect(wrapper.find('[data-test="payout-entry-review"]').text()).toContain(
      "No receipt",
    );
  });
});
