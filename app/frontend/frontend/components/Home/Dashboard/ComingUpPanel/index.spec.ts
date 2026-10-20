import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { FleetEvent, GameEvent, MyEvent } from "@/services/fyApi";
import Component from "./index.vue";

let items: Partial<MyEvent>[] = [];
const signup = vi.fn();

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useMyEvents: () => ({
      data: computed(() => ({ items })),
      isLoading: ref(false),
      isFetching: ref(false),
      isLoadingError: ref(false),
    }),
    useSignupFleetEvent: () => ({ mutateAsync: signup }),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleets", name: "fleets", component: Stub },
      {
        path: "/settings/calendar",
        name: "settings-calendar",
        component: Stub,
      },
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

const inDays = (days: number) =>
  new Date(Date.now() + days * 86_400_000).toISOString();

const fleetEntry = (overrides: Partial<FleetEvent> = {}): Partial<MyEvent> => {
  const fleetEvent = {
    id: overrides.id || "e1",
    slug: "mining-op",
    title: "Mining op",
    status: "open",
    startsAt: inDays(2),
    signupsOpen: true,
    viewerSignup: null,
    ...overrides,
  } as FleetEvent;

  return {
    type: "fleet_event",
    startsAt: fleetEvent.startsAt,
    fleet: { id: "f", name: "Nova Wing", slug: "nova-wing" },
    fleetEvent,
  };
};

const gameEntry = (overrides: Partial<GameEvent> = {}): Partial<MyEvent> => {
  const gameEvent = {
    id: "g1",
    title: "Invictus Launch Week",
    category: "ship_combat",
    startsAt: inDays(10),
    createdAt: inDays(-1),
    updatedAt: inDays(-1),
    ...overrides,
  } as GameEvent;

  return { type: "game_event", startsAt: gameEvent.startsAt, gameEvent };
};

const mount = async () =>
  mountWithDefaults<typeof Component>(Component, {
    plugins: [await router()],
  });

describe("HomeDashboardComingUpPanel", () => {
  beforeEach(() => {
    items = [];
    signup.mockReset().mockResolvedValue({});
  });

  it("groups the agenda by how soon it is", async () => {
    items = [
      fleetEntry({ id: "today", title: "Cargo run", startsAt: inDays(0) }),
      fleetEntry({ id: "week", title: "Mining op", startsAt: inDays(2) }),
      gameEntry(),
    ];

    const subject = await mount();

    expect(
      subject.findAll(".home-coming-up__group").map((group) => group.text()),
    ).toEqual(["Today", "This week", "Later"]);
    expect(
      subject.findAll(".event-card__title").map((title) => title.text()),
    ).toEqual(["Cargo run", "Mining op", "Invictus Launch Week"]);
  });

  it("leaves out cancelled and completed fleet events", async () => {
    items = [
      fleetEntry({ id: "a", title: "On", status: "open" }),
      fleetEntry({ id: "b", title: "Off", status: "cancelled" }),
      fleetEntry({ id: "c", title: "Done", status: "completed" }),
    ];

    const subject = await mount();

    expect(
      subject.findAll(".event-card__title").map((title) => title.text()),
    ).toEqual(["On"]);
  });

  it("signs the reader up for an occurrence straight from the agenda", async () => {
    items = [
      fleetEntry({
        slug: "weekly-run-2026-10-24",
        parentEventSlug: "weekly-run",
        occurrenceDate: "2026-10-24",
      }),
    ];

    const subject = await mount();

    await subject.findAll(".home-coming-up__meta .btn")[0].trigger("click");
    await flushPromises();

    expect(signup).toHaveBeenCalledWith({
      fleetSlug: "nova-wing",
      slug: "weekly-run",
      data: { status: "confirmed", occurrenceDate: "2026-10-24" },
    });
  });

  it("offers no sign-up once the reader has answered", async () => {
    items = [
      fleetEntry({
        viewerSignup: { id: "s", status: "confirmed" } as never,
      }),
    ];

    const subject = await mount();

    expect(subject.find(".home-coming-up__meta .btn").exists()).toBe(false);
  });

  it("says nothing is planned when the agenda is empty", async () => {
    const subject = await mount();

    expect(subject.find("[data-test='dashboard-empty']").exists()).toBe(true);
  });
});
