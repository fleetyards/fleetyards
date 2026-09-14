import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import Component from "./index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import type { Tour } from "@/services/fyApi";

const tour = (overrides: Partial<Tour> = {}): Tour =>
  ({
    id: "tour-1",
    title: "Jumptown Run",
    slug: "abc-jumptown-run",
    status: "open",
    participating: false,
    joinRequestPending: false,
    fleet: { id: "fleet-1", name: "Blue Sun", slug: "blue-sun" },
    ...overrides,
  }) as Tour;

const wrappers: Array<{ unmount: () => void }> = [];

const mount = async (props: { tour: Tour; manageable?: boolean }) => {
  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props,
  });
  wrappers.push(wrapper);
  return wrapper;
};

// The actions are teleported into the page header, so they land outside the
// wrapper and have to be read off the document.
const header = () => document.getElementById("header-right")?.textContent ?? "";

beforeEach(() => {
  document.body.innerHTML = '<div id="header-right"></div>';
});

afterEach(() => {
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }
  document.body.innerHTML = "";
});

describe("TourDetails", () => {
  it("offers asking onto a fleet tour the viewer is not on", async () => {
    await mount({ tour: tour() });

    expect(header()).toContain("Ask to participate");
  });

  // A standalone tour is not listed anywhere a stranger could have found it,
  // so its link is the only way in and there is nobody to ask.
  it("does not offer asking onto a standalone tour", async () => {
    await mount({ tour: tour({ fleet: undefined }) });

    expect(header()).not.toContain("Ask to participate");
  });

  it("does not offer asking once the viewer is on the tour", async () => {
    await mount({ tour: tour({ participating: true }) });

    expect(header()).not.toContain("Ask to participate");
  });

  it("does not offer asking onto a settled tour", async () => {
    await mount({ tour: tour({ status: "settled" }) });

    expect(header()).not.toContain("Ask to participate");
  });

  it("offers withdrawing an ask that is still unanswered", async () => {
    await mount({
      tour: tour({ joinRequestPending: true, joinRequestId: "request-1" }),
    });

    expect(header()).toContain("Withdraw request");
    expect(header()).not.toContain("Ask to participate");
  });

  // The ledger has its own channel; the viewer's standing on the tour rides on
  // the tour payload, which only the page can refetch. Without this an
  // approved ask still reads as pending until a reload.
  it("asks the page to reload when the ledger changes", async () => {
    const wrapper = await mount({
      tour: tour({ joinRequestPending: true, joinRequestId: "request-1" }),
    });

    useComlink().emit("payout-ledger-changed");
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted("reload")).toBeTruthy();
  });

  it("says an ask is waiting for an answer", async () => {
    const wrapper = await mount({
      tour: tour({ joinRequestPending: true, joinRequestId: "request-1" }),
    });

    expect(
      wrapper.find('[data-test="tour-join-request-pending"]').exists(),
    ).toBe(true);
  });
});
