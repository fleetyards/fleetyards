import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { PayoutParticipant } from "@/services/fyApi";

// The generated hook calls its fetcher from inside its own module, so mocking
// that export changes nothing -- the request has to be intercepted at the
// client. Inline rather than a shared const: vi.mock is hoisted above every
// top-level binding in the file, so the factory cannot close over one.
vi.mock("@/services/axiosClient", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  axiosClient: vi.fn().mockResolvedValue([
    {
      id: "request-1",
      tourId: "tour-1",
      status: "pending",
      user: { id: "user-2", username: "Kaylee" },
    },
  ]),
}));

const participant = (
  overrides: Partial<PayoutParticipant> = {},
): PayoutParticipant =>
  ({
    id: "participant-1",
    payoutLedgerId: "ledger-1",
    displayName: "Mal",
    guest: false,
    weight: "1.0",
    ...overrides,
  }) as PayoutParticipant;

const wrappers: Array<{ unmount: () => void }> = [];

const mount = async (props: {
  payoutLedgerId: string;
  participants: PayoutParticipant[];
  manageable?: boolean;
  tourSlug?: string;
}) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props,
  });
  wrappers.push(wrapper);
  await new Promise((resolve) => setTimeout(resolve, 0));
  await wrapper.vm.$nextTick();
  return wrapper;
};

afterEach(() => {
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }
});

describe("PayoutParticipantList", () => {
  // Answering an ask is the same decision as adding somebody, so it belongs on
  // the list rather than in a queue of its own.
  it("lists whoever has asked to be on it, with both answers", async () => {
    const wrapper = await mount({
      payoutLedgerId: "ledger-1",
      participants: [participant()],
      manageable: true,
      tourSlug: "abc-jumptown-run",
    });

    const rows = wrapper.findAll('[data-test="payout-participant-request"]');

    expect(rows).toHaveLength(1);
    expect(rows[0].text()).toContain("Kaylee");
    expect(
      wrapper.find('[data-test="payout-participant-request-approve"]').exists(),
    ).toBe(true);
    expect(
      wrapper.find('[data-test="payout-participant-request-decline"]').exists(),
    ).toBe(true);
  });

  // Only whoever may answer is shown them -- the API refuses the list to
  // anyone else, so asking for it would be a 403 on every page view.
  it("leaves them out for somebody who cannot answer", async () => {
    const wrapper = await mount({
      payoutLedgerId: "ledger-1",
      participants: [participant()],
      manageable: false,
      tourSlug: "abc-jumptown-run",
    });

    expect(
      wrapper.findAll('[data-test="payout-participant-request"]'),
    ).toHaveLength(0);
  });

  // A fleet event's ledger has no tour behind it, and nobody asks onto one.
  it("leaves them out without a tour", async () => {
    const wrapper = await mount({
      payoutLedgerId: "ledger-1",
      participants: [participant()],
      manageable: true,
    });

    expect(
      wrapper.findAll('[data-test="payout-participant-request"]'),
    ).toHaveLength(0);
  });
});
