import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetEventExtended, FleetMember } from "@/services/fyApi";
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

const recurringEvent = (excludedDates: string[]): FleetEventExtended =>
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

const mount = async (excludedDates: string[]) => {
  current.value = recurringEvent(excludedDates);

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
});
