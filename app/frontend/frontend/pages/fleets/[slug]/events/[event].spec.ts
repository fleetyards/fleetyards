import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type {
  Fleet,
  FleetEventExtended,
  FleetMember,
  User,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import Component from "./[event].vue";

const Stub = defineComponent({ name: "PageStub", render: () => h("div") });

const { ChildStub } = vi.hoisted(() => ({
  ChildStub: { name: "ChildStub", render: () => null },
}));

vi.mock("@/frontend/components/Fleets/Events/EventTeamCard/index.vue", () => ({
  default: ChildStub,
}));
vi.mock("@/frontend/components/Fleets/Events/EventSignupCta/index.vue", () => ({
  default: ChildStub,
}));
vi.mock(
  "@/frontend/components/Fleets/Events/EventAdminActions/index.vue",
  () => ({ default: ChildStub }),
);
vi.mock(
  "@/frontend/components/Fleets/Events/UnassignedSignups/index.vue",
  () => ({ default: ChildStub }),
);
vi.mock(
  "@/frontend/components/Fleets/Events/YourSignupPanel/index.vue",
  () => ({ default: ChildStub }),
);

const routerWithRoutes = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleet", name: "fleet", component: Stub },
      { path: "/events", name: "fleet-events", component: Stub },
      { path: "/events/:event", name: "fleet-event", component: Stub },
      {
        path: "/events/:event/edit/schedule",
        name: "fleet-event-edit-schedule",
        component: Stub,
      },
      {
        path: "/events/:event/payouts",
        name: "fleet-event-payouts",
        component: Stub,
      },
    ],
  });

  await router.push("/events/weekly-op");
  await router.isReady();

  return router;
};

const current = ref<FleetEventExtended | undefined>();
const refetch = vi.fn();
const skip = vi.fn();
const unskip = vi.fn();
const displayConfirm = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
    displayConfirm,
  }),
}));

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetEvent: () => ({
      data: current,
      isLoading: ref(false),
      refetch,
    }),
    useSkipFleetEventOccurrence: () => ({ mutateAsync: skip }),
    useUnskipFleetEventOccurrence: () => ({ mutateAsync: unskip }),
    useEndFleetEventSeries: () => ({ mutateAsync: vi.fn() }),
  };
});

// The page lists occurrences from now on, so the series starts tomorrow.
const startsAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
const firstOccurrence = startsAt.toISOString().slice(0, 10);

const recurringEvent = (
  excludedDates: string[],
  seriesStart: boolean,
): FleetEventExtended =>
  ({
    id: "event",
    slug: "weekly-op",
    title: "Weekly Op",
    status: "open",
    past: false,
    startsAt: startsAt.toISOString(),
    recurring: true,
    recurrenceInterval: "weekly",
    excludedDates,
    upcomingOccurrences: [
      {
        date: firstOccurrence,
        startsAt: startsAt.toISOString(),
        excluded: excludedDates.includes(firstOccurrence),
        seriesStart,
      },
    ],
    teams: [],
  }) as unknown as FleetEventExtended;

let wrapper: VueWrapper | undefined;

// The hero cover is lazy-loaded and jsdom has no IntersectionObserver.
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

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  current.value = undefined;
  vi.clearAllMocks();
});

const mount = async (excludedDates: string[], seriesStart = true) => {
  current.value = recurringEvent(excludedDates, seriesStart);

  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", name: "Maru" } as Fleet,
      membership: {} as FleetMember,
      resourceAccess: ["fleet:events:manage"],
    },
    plugins: [await routerWithRoutes()],
  });

  return wrapper;
};

describe("FleetEventPage occurrences", () => {
  it("restores a skipped occurrence by its date", async () => {
    const subject = await mount([firstOccurrence]);

    await subject
      .find(`[data-test='unskip-occurrence-${firstOccurrence}']`)
      .trigger("click");

    expect(unskip).toHaveBeenCalledWith({
      fleetSlug: "maru",
      slug: "weekly-op",
      data: { date: firstOccurrence },
    });
    expect(refetch).toHaveBeenCalled();
  });

  it("offers no restore on an occurrence that is not skipped", async () => {
    const subject = await mount([]);

    expect(
      subject
        .find(`[data-test='unskip-occurrence-${firstOccurrence}']`)
        .exists(),
    ).toBe(false);
  });

  it("splits a later occurrence even when the page is scoped to it", async () => {
    // An occurrence-scoped response shifts startsAt onto that occurrence, so
    // only the server's seriesStart can tell it apart from the series start.
    const subject = await mount([], false);

    await subject
      .find(`[data-test='split-series-${firstOccurrence}']`)
      .trigger("click");

    expect(displayConfirm).toHaveBeenCalled();
  });

  it("edits the whole series from its first occurrence", async () => {
    const subject = await mount([]);

    await subject
      .find(`[data-test='split-series-${firstOccurrence}']`)
      .trigger("click");

    expect(displayConfirm).not.toHaveBeenCalled();
  });
});

describe("FleetEventPage own seats", () => {
  const mine = { user: { id: "me" }, status: "confirmed" };

  const seatedEvent = (): FleetEventExtended =>
    ({
      ...recurringEvent([], true),
      recurring: false,
      upcomingOccurrences: [],
      teams: [
        {
          id: "team",
          title: "Alpha",
          slots: [{ id: "lead", title: "Lead", signups: [mine] }],
          ships: [
            {
              id: "ship",
              title: "Gladius",
              slots: [{ id: "pilot", title: "Pilot", signups: [mine] }],
            },
          ],
        },
      ],
    }) as unknown as FleetEventExtended;

  const childAttrs = (subject: VueWrapper, key: string) =>
    subject
      .findAllComponents(ChildStub)
      .map((child) => child.vm.$attrs)
      .find((attrs) => key in attrs) as Record<string, unknown>;

  it("keeps a team seat from blocking a ship seat, and the other way round", async () => {
    current.value = seatedEvent();
    wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        fleet: { slug: "maru", name: "Maru" } as Fleet,
        membership: {} as FleetMember,
        resourceAccess: ["fleet:events:read"],
      },
      plugins: [await routerWithRoutes()],
    });
    useSessionStore().currentUser = { id: "me" } as User;
    await nextTick();

    const team = childAttrs(wrapper, "own-active-slot-id");
    expect(team["own-active-slot-id"]).toBe("pilot");
    expect(team["own-team-seat-slot-id"]).toBe("lead");

    const panel = childAttrs(wrapper, "slot-title");
    expect(panel["slot-title"]).toBe("Pilot");
    expect(team["team-seat-leavable"]).toBe(true);
  });

  it("leads with the pool signup over a team seat", async () => {
    const seated = seatedEvent() as unknown as {
      teams: { ships: unknown[] }[];
      unassignedSignups: unknown[];
    };
    seated.teams[0].ships = [];
    seated.unassignedSignups = [{ ...mine, status: "interested" }];
    current.value = seated as unknown as FleetEventExtended;
    wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        fleet: { slug: "maru", name: "Maru" } as Fleet,
        membership: {} as FleetMember,
        resourceAccess: ["fleet:events:read"],
      },
      plugins: [await routerWithRoutes()],
    });
    useSessionStore().currentUser = { id: "me" } as User;
    await nextTick();

    const panel = childAttrs(wrapper, "slot-title");
    expect((panel.signup as { status: string }).status).toBe("interested");

    const team = childAttrs(wrapper, "own-active-slot-id");
    expect(team["own-active-slot-id"]).toBeNull();
    expect(team["own-team-seat-slot-id"]).toBe("lead");
    expect(team["team-seat-leavable"]).toBe(true);
  });
});
