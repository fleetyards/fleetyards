import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import Component from "./index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import type { Tour } from "@/services/fyApi";
import { createMemoryHistory, createRouter } from "vue-router";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";

const page = { template: "<div />" };

// The share link is resolved through the named routes, which the default test
// router does not declare.
const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/fleets/:slug/tours/:tour/", name: "fleet-tour", component: page },
    { path: "/tools/tours/:slug/", name: "tour", component: page },
  ],
});

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
    plugins: [router],
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

  it("shares the invite link with someone who may invite", async () => {
    const wrapper = await mount({ tour: tour({ inviteToken: "tok123" }) });

    expect(wrapper.findComponent(ShareBtn).props("url")).toBe(
      `${window.location.origin}/tools/tours/join/tok123/`,
    );
  });

  it("shares a fleet tour's page with anyone else", async () => {
    const wrapper = await mount({ tour: tour() });

    expect(wrapper.findComponent(ShareBtn).props("url")).toBe(
      `${window.location.origin}/fleets/blue-sun/tours/abc-jumptown-run/`,
    );
  });

  it("shares a standalone tour's own page", async () => {
    const wrapper = await mount({ tour: tour({ fleet: undefined }) });

    expect(wrapper.findComponent(ShareBtn).props("url")).toBe(
      `${window.location.origin}/tools/tours/abc-jumptown-run/`,
    );
  });
});
