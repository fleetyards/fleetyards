import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetEvent } from "@/services/fyApi";
import Component from "./index.vue";

let items: Partial<FleetEvent>[] = [];

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
    props: {
      fleet: { slug: "maru" } as Fleet,
      events: items as FleetEvent[],
    },
    plugins: [await router()],
  });

const titles = (subject: Awaited<ReturnType<typeof mount>>) =>
  subject
    .findAll("[data-test='fleet-dashboard-event'] .event-card__title")
    .map((link) => link.text());

describe("FleetDashboardUpcomingEventsPanel", () => {
  beforeEach(() => {
    items = [];
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

  // The dashboard's answer may reach past the two weeks, for the week shown.
  it("leaves out what starts past the next two weeks", async () => {
    items = [
      event({ id: "a", title: "Soon" }),
      event({
        id: "b",
        title: "Later",
        startsAt: new Date(Date.now() + 20 * 86_400_000).toISOString(),
      }),
    ];

    expect(titles(await mount())).toEqual(["Soon"]);
  });

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

  // A recurring date is a page of the series, opened at that occurrence.
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
