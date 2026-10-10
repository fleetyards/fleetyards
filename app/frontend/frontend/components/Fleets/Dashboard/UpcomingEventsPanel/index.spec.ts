import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetEvent } from "@/services/fyApi";
import Component from "./index.vue";

let items: Partial<FleetEvent>[] = [];
let askedFor: { from?: string; to?: string } | undefined;
const isLoading = ref(false);
const isFetching = ref(false);

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetCalendar: (
      _slug: unknown,
      params: { value: { from?: string; to?: string } },
    ) => {
      askedFor = params.value;

      return {
        data: computed(() => ({ items })),
        isLoading,
        isFetching,
      };
    },
  };
});

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleets/:slug/events", name: "fleet-events", component: Stub },
      {
        path: "/fleets/:slug/events/:event",
        name: "fleet-event",
        component: Stub,
      },
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

const event = (overrides: Partial<FleetEvent>): Partial<FleetEvent> => ({
  id: "e",
  slug: "mining-op",
  title: "Mining op",
  status: "open",
  startsAt: new Date(Date.now() + 86_400_000).toISOString(),
  signupsOpen: true,
  viewerSignup: null,
  ...overrides,
});

const mount = async () =>
  mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet },
    plugins: [await router()],
  });

const titles = (subject: Awaited<ReturnType<typeof mount>>) =>
  subject
    .findAll("[data-test='fleet-dashboard-event'] .event-card__title")
    .map((link) => link.text());

describe("FleetDashboardUpcomingEventsPanel", () => {
  beforeEach(() => {
    items = [];
    askedFor = undefined;
    isLoading.value = false;
    isFetching.value = false;
  });

  it("stands in its place, loading, until the first answer is in", async () => {
    isLoading.value = true;
    isFetching.value = true;

    const subject = await mount();

    expect(subject.find("[data-test='fleet-dashboard-events']").exists()).toBe(
      true,
    );
    expect(subject.find(".panel--loading").exists()).toBe(true);
  });

  it("shows a refetch as loading too", async () => {
    items = [event({})];
    isFetching.value = true;

    expect((await mount()).find(".panel--loading").exists()).toBe(true);
  });

  // From yesterday: the calendar answers by start time, and an op that began
  // last night may still be running.
  it("asks the calendar from yesterday to two weeks out", async () => {
    await mount();

    const from = new Date(askedFor?.from ?? "");
    const to = new Date(askedFor?.to ?? "");
    expect(Math.round((+to - +from) / 86_400_000)).toBe(15);
    expect(from.getTime()).toBeLessThan(Date.now() - 86_400_000 / 2);
  });

  it("leaves out what nobody is going to", async () => {
    items = [
      event({ id: "a", title: "Open" }),
      event({ id: "b", title: "Draft", status: "draft" }),
      event({ id: "c", title: "Cancelled", status: "cancelled" }),
    ];

    expect(titles(await mount())).toEqual(["Open"]);
  });

  it("shows the reader's own signup, or offers one", async () => {
    items = [
      event({
        id: "a",
        viewerSignup: { id: "s", status: "tentative" },
      }),
      event({ id: "b", slug: "salvage" }),
      event({ id: "c", slug: "closed", signupsOpen: false }),
    ];

    const subject = await mount();

    expect(
      subject.findAll("[data-test='fleet-dashboard-event-signup']"),
    ).toHaveLength(1);
    expect(
      subject.find("[data-test='fleet-dashboard-event-signup']").text(),
    ).toBe("Tentative");
    expect(
      subject.findAll("[data-test='fleet-dashboard-event-signup-cta']"),
    ).toHaveLength(1);
  });

  // A recurring date is a page of the series, opened at that occurrence.
  // An op that began this morning and runs until tonight is still the one the
  // reader is in; one that already ended is not upcoming.
  it("keeps what is underway and drops what has ended", async () => {
    const hoursAgo = (hours: number) =>
      new Date(Date.now() - hours * 3_600_000).toISOString();

    items = [
      event({
        id: "a",
        title: "Underway",
        status: "active",
        startsAt: hoursAgo(2),
        endsAt: new Date(Date.now() + 3_600_000).toISOString(),
      }),
      event({
        id: "b",
        title: "Over",
        startsAt: hoursAgo(3),
        endsAt: hoursAgo(1),
      }),
    ];

    expect(titles(await mount())).toEqual(["Underway"]);
  });

  it("links an occurrence to its series", async () => {
    items = [
      event({
        slug: "weekly-2026-05-21",
        parentEventSlug: "weekly",
        occurrenceDate: "2026-05-21",
      }),
    ];

    const subject = await mount();

    expect(subject.find("a.event-card").attributes("href")).toBe(
      "#/fleets/maru/events/weekly?occurrence=2026-05-21",
    );
  });
});
