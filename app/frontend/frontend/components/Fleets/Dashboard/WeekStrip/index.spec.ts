import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref, type Ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetEvent } from "@/services/fyApi";
import Component from "./index.vue";

let items: Partial<FleetEvent>[] = [];
let params: Ref<{ from: string; to: string }> | undefined;
const isLoading = ref(false);
const isError = ref(false);

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetCalendar: (
      _slug: unknown,
      range: Ref<{ from: string; to: string }>,
    ) => {
      params = range;

      return {
        data: computed(() =>
          isLoading.value || isError.value ? undefined : { items },
        ),
        isLoading,
        isFetching: isLoading,
        isError,
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

// A Wednesday, so the week runs Monday the 5th to Sunday the 11th.
const NOW = new Date(2026, 9, 7, 12, 0);

const at = (day: number, hours = 20) =>
  new Date(2026, 9, day, hours, 0).toISOString();

const event = (overrides: Partial<FleetEvent>): Partial<FleetEvent> => ({
  id: "e",
  slug: "cargo-run",
  title: "Cargo Run",
  status: "open",
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
    .findAll("[data-test='fleet-dashboard-week-event'] .event-card__title")
    .map((title) => title.text());

describe("FleetDashboardWeekStrip", () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(NOW);
    items = [];
    isLoading.value = false;
    isError.value = false;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("draws every day of the week, busy or not", async () => {
    items = [event({ startsAt: at(10) })];

    const subject = await mount();
    const days = subject.findAll("[data-test='fleet-dashboard-week-day']");

    expect(days.map((day) => day.find(".week-strip__number").text())).toEqual([
      "5",
      "6",
      "7",
      "8",
      "9",
      "10",
      "11",
    ]);
    expect(
      days.map((day) => day.find(".week-strip__dot--on").exists()),
    ).toEqual([false, false, false, false, false, true, false]);
  });

  it("opens on today and lists the day picked", async () => {
    items = [
      event({ id: "a", title: "Today's op", startsAt: at(7) }),
      event({ id: "b", title: "Saturday op", startsAt: at(10) }),
      event({ id: "c", title: "Drafted", status: "draft", startsAt: at(10) }),
    ];

    const subject = await mount();

    expect(titles(subject)).toEqual(["Today's op"]);

    await subject
      .findAll("[data-test='fleet-dashboard-week-day']")[5]
      .trigger("click");

    expect(titles(subject)).toEqual(["Saturday op"]);
  });

  // An op that runs past midnight is on the second day too, and one that began
  // the Sunday before still counts for Monday.
  it("marks every day an event runs into", async () => {
    items = [
      event({
        id: "a",
        title: "Night op",
        startsAt: new Date(2026, 9, 4, 22, 0).toISOString(),
        endsAt: new Date(2026, 9, 5, 2, 0).toISOString(),
      }),
    ];

    const subject = await mount();
    const days = subject.findAll("[data-test='fleet-dashboard-week-day']");

    expect(days[0].find(".week-strip__dot--on").exists()).toBe(true);
    expect(days[1].find(".week-strip__dot--on").exists()).toBe(false);
    expect(new Date(params?.value.from ?? "").getDate()).toBe(4);
  });

  it("says so when the day picked has nothing on", async () => {
    const subject = await mount();

    expect(subject.find(".week-strip__empty").exists()).toBe(true);
  });

  it("says nothing about the day before its week has been answered", async () => {
    isLoading.value = true;

    const subject = await mount();

    expect(subject.find(".week-strip__empty").exists()).toBe(false);
    expect(subject.find(".panel--loading").exists()).toBe(true);
  });

  it("says the week failed rather than that the day is free", async () => {
    isError.value = true;

    const subject = await mount();

    expect(subject.find(".week-strip__empty").text()).toBe(
      "This could not be loaded right now.",
    );
  });

  it("asks for the next week when moved on", async () => {
    const subject = await mount();

    await subject.find("[aria-label='Next']").trigger("click");

    // The Sunday before the week of the 12th, for what runs over midnight.
    expect(new Date(params?.value.from ?? "").getDate()).toBe(11);
  });
});
