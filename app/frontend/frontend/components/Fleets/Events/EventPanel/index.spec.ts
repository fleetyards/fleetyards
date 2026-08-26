import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import {
  type Fleet,
  type FleetEvent,
  MissionCategoryEnum,
  FleetEventSignupApprovalEnum,
  FleetEventStatusEnum,
  FleetEventVisibilityEnum,
} from "@/services/fyApi";

// The card carries a cover image, and jsdom has no IntersectionObserver for
// useLazyBackground to hand it to. Re-stubbed per test rather than once: another
// spec sharing this worker can call unstubAllGlobals between them, and without
// the observer the panel body never renders - which showed up once as this file
// failing in a full run and passing on its own.
beforeEach(() => {
  vi.stubGlobal(
    "IntersectionObserver",
    class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  );
});

const NOW = "2026-09-04T19:30:00Z";

const fleet: Fleet = {
  features: [],
  id: "fleet-1",
  fid: "SILENTWINGS",
  name: "Silent Wings",
  slug: "silent-wings",
  publicFleet: true,
  publicFleetStats: true,
  createdAt: NOW,
  updatedAt: NOW,
};

const event = (overrides: Partial<FleetEvent> = {}): FleetEvent => ({
  id: "event-1",
  fleetId: fleet.id,
  title: "Jumptown Convoy Escort",
  slug: "jumptown",
  status: FleetEventStatusEnum.OPEN,
  startsAt: NOW,
  timezone: "UTC",
  visibility: FleetEventVisibilityEnum.FLEET,
  category: MissionCategoryEnum.CARGO_HAULING,
  autoLockEnabled: true,
  signupApproval: FleetEventSignupApprovalEnum.DIRECT,
  archived: false,
  externalUid: "uid-1",
  signupsCount: 14,
  teamCount: 2,
  past: false,
  signupsOpen: true,
  discordConfigured: false,
  createdAt: NOW,
  updatedAt: NOW,
  ...overrides,
});

// The title is a router-link, and TestUtils' default router only knows `home`.
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: "/fleets/:slug/events/:event",
      name: "fleet-event",
      component: { template: "<div />" },
    },
  ],
});

const mount = (record: FleetEvent) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { fleet, event: record },
    plugins: [router],
  });

describe("FleetEventsPanel", () => {
  it("carries the lifecycle on the panel's tone, not a badge", async () => {
    const wrapper = await mount(event({ status: FleetEventStatusEnum.OPEN }));

    // D1: the cap carries status, the frame stays neutral. EventStatusBadge,
    // which painted its own fill and pinned itself to `top: 120px`, is gone.
    expect(wrapper.find(".panel--success").exists()).toBe(true);
    expect(wrapper.find(".event-status-badge").exists()).toBe(false);
  });

  it("gives each lifecycle state its own tone", async () => {
    const cases: Array<[FleetEventStatusEnum, string]> = [
      [FleetEventStatusEnum.DRAFT, "panel--neutral"],
      [FleetEventStatusEnum.LOCKED, "panel--highlight"],
      [FleetEventStatusEnum.ACTIVE, "panel--primary"],
      [FleetEventStatusEnum.CANCELLED, "panel--error"],
    ];

    for (const [status, expected] of cases) {
      const wrapper = await mount(event({ status }));

      if (expected === "panel--neutral") {
        // Neutral is the absence of a tone class, not a class of its own.
        expect(wrapper.find(".panel--error").exists()).toBe(false);
        expect(wrapper.find(".panel--success").exists()).toBe(false);
      } else {
        expect(wrapper.find(`.${expected}`).exists()).toBe(true);
      }
    }
  });

  it("reads a past event as past rather than as open signups", async () => {
    const wrapper = await mount(
      event({ status: FleetEventStatusEnum.OPEN, past: true }),
    );

    // Still `open` on the record, but nothing should advertise open signups.
    expect(wrapper.find(".panel--success").exists()).toBe(false);
  });

  it("names the status as well as colouring it", async () => {
    // WCAG 1.4.1: four of the seven states share the neutral tone, so the cap
    // cannot be the only thing distinguishing them either.
    const wrapper = await mount(event({ status: FleetEventStatusEnum.LOCKED }));
    const badge = wrapper.find('[data-test="event-status"]');

    expect(badge.exists()).toBe(true);
    expect(badge.text()).not.toBe("");
  });

  it("renders the meta as metrics rows rather than an icon list", async () => {
    const wrapper = await mount(
      event({ location: "Levski", meetupLocation: "Olisar" }),
    );

    expect(wrapper.findAll(".metrics-card__row").length).toBeGreaterThan(1);
    expect(wrapper.text()).toContain("Levski");
    expect(wrapper.text()).toContain("Olisar");
  });

  it("sets the cover height through Panel's own property", async () => {
    // D2: the four :deep() rules this replaces reached into Panel's internals,
    // and two of them had stopped matching anything at all.
    const wrapper = await mount(event());

    expect(wrapper.find(".event-panel").exists()).toBe(true);
    expect(wrapper.html()).not.toContain("panel-inner");
  });
});
