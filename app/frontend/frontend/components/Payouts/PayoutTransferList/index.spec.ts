import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { PayoutTransfer } from "@/services/fyApi";

const participant = (id: string, displayName: string) => ({
  id,
  payoutLedgerId: "ledger-1",
  displayName,
  guest: false,
});

const transfer = (overrides: Partial<PayoutTransfer> = {}): PayoutTransfer =>
  ({
    id: "t1",
    payoutLedgerId: "ledger-1",
    amount: "308000.0",
    confirmed: false,
    from: participant("p1", "Bob"),
    to: participant("p2", "Alice"),
    ...overrides,
  }) as PayoutTransfer;

const wrappers: Array<{ unmount: () => void }> = [];

const mount = async (props: {
  transfers: PayoutTransfer[];
  preview?: boolean;
  loading?: boolean;
}) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { payoutLedgerId: "ledger-1", ...props },
  });
  wrappers.push(wrapper);
  return wrapper;
};

afterEach(() => {
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }
});

describe("PayoutTransferList", () => {
  it("names both ends of a transfer", async () => {
    const wrapper = await mount({ transfers: [transfer()] });

    expect(wrapper.text()).toContain("Bob");
    expect(wrapper.text()).toContain("Alice");
  });

  it("says what to do when there is nothing to settle", async () => {
    const wrapper = await mount({ transfers: [] });

    expect(wrapper.findAll("[data-test='payout-transfer']")).toHaveLength(0);
    expect(wrapper.find(".payout-transfers__empty").exists()).toBe(true);
  });

  // The transfers are a request of their own, answering after the ledger that
  // frames this panel - so the empty text used to be what a reader saw of a
  // settled ledger for as long as reading it took.
  it("waits rather than saying there is nothing to settle", async () => {
    const wrapper = await mount({ transfers: [], loading: true });

    expect(wrapper.find(".payout-transfers__empty").exists()).toBe(false);
    expect(wrapper.find("[data-test='rows-skeleton']").exists()).toBe(true);
  });

  // A refetch keeps the rows it already has, and they hold the panel open
  // better than placeholders would.
  it("keeps the rows it has while they are being refetched", async () => {
    const wrapper = await mount({ transfers: [transfer()], loading: true });

    expect(wrapper.find("[data-test='rows-skeleton']").exists()).toBe(false);
    expect(wrapper.findAll("[data-test='payout-transfer']")).toHaveLength(1);
  });

  // While the ledger is open the list is recomputed from the entries and
  // nobody has agreed to pay it, so there is nothing to tick off yet.
  it("offers no confirm button on a preview", async () => {
    const wrapper = await mount({ transfers: [transfer()], preview: true });

    expect(wrapper.find("button").exists()).toBe(false);
  });

  it("offers a confirm button once settled", async () => {
    const wrapper = await mount({ transfers: [transfer()], preview: false });

    expect(wrapper.find("button").exists()).toBe(true);
  });

  it("marks a confirmed transfer", async () => {
    const wrapper = await mount({
      transfers: [transfer({ confirmed: true })],
      preview: false,
    });

    expect(wrapper.find(".payout-transfers__row--confirmed").exists()).toBe(
      true,
    );
  });
});
