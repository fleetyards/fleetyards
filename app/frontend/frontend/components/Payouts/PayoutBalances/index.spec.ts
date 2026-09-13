import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { PayoutBalance } from "@/services/fyApi";

const participant = (id: string, displayName: string, guest = false) => ({
  id,
  payoutLedgerId: "ledger-1",
  displayName,
  guest,
});

const balance = (overrides: Partial<PayoutBalance> = {}): PayoutBalance =>
  ({
    participant: participant("p1", "Alice"),
    paid: "0.0",
    held: "0.0",
    share: "0.0",
    net: "0.0",
    ...overrides,
  }) as PayoutBalance;

// A wrapper left mounted keeps its pinia store alive, which makes the next
// test assert against a second store and pass either way.
const wrappers: Array<{ unmount: () => void }> = [];

const mount = async (balances: PayoutBalance[]) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { balances },
  });
  wrappers.push(wrapper);
  return wrapper;
};

afterEach(() => {
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }
});

describe("PayoutBalances", () => {
  it("renders a row per participant", async () => {
    const wrapper = await mount([
      balance({ participant: participant("p1", "Alice") }),
      balance({ participant: participant("p2", "Bob") }),
    ]);

    expect(wrapper.findAll("[data-test^='payout-balance-']")).toHaveLength(2);
    expect(wrapper.text()).toContain("Alice");
    expect(wrapper.text()).toContain("Bob");
  });

  // A negative net means they are owed, and the list is easier to read as an
  // absolute amount plus a colour than as a minus sign.
  it("shows a debtor and a creditor differently", async () => {
    const wrapper = await mount([
      balance({ participant: participant("p1", "Alice"), net: "604000.0" }),
      balance({ participant: participant("p2", "Bob"), net: "-604000.0" }),
    ]);

    const rows = wrapper.findAll("[data-test^='payout-balance-']");

    expect(rows[0].find(".payout-balances__net--owes").exists()).toBe(true);
    expect(rows[1].find(".payout-balances__net--owed").exists()).toBe(true);
  });

  it("does not colour a settled-up participant", async () => {
    const wrapper = await mount([balance({ net: "0.0" })]);

    const row = wrapper.find("[data-test^='payout-balance-']");

    expect(row.find(".payout-balances__net--owes").exists()).toBe(false);
    expect(row.find(".payout-balances__net--owed").exists()).toBe(false);
  });

  it("marks a guest", async () => {
    const wrapper = await mount([
      balance({ participant: participant("p3", "Kev", true) }),
    ]);

    expect(wrapper.find(".payout-balances__tag").exists()).toBe(true);
  });

  it("renders nothing but the header without balances", async () => {
    const wrapper = await mount([]);

    expect(wrapper.findAll("[data-test^='payout-balance-']")).toHaveLength(0);
  });
});
