import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import { defineRule } from "vee-validate";
import { between, required } from "@vee-validate/rules";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import { type Fleet, type FleetEventExtended } from "@/services/fyApi";
import Component from "./schedule.vue";

const mutateAsync = vi.fn();

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useUpdateFleetEvent: () => ({ mutateAsync }),
  };
});

let wrapper: VueWrapper | undefined;

beforeAll(() => {
  defineRule("required", required);
  defineRule("between", between);
});

beforeEach(() => {
  mutateAsync.mockReset().mockResolvedValue({});
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

// A Tuesday evening in Berlin, repeating every two weeks on Tue and Thu.
const series = (attrs: Partial<FleetEventExtended> = {}) =>
  ({
    slug: "op",
    startsAt: "2026-10-06T18:00:00Z",
    timezone: "Europe/Berlin",
    recurring: true,
    recurrenceInterval: "weekly",
    recurrenceEvery: 2,
    recurrenceWeekdays: [2, 4],
    teams: [],
    unassignedSignups: [],
    upcomingOccurrences: [],
    ...attrs,
  }) as unknown as FleetEventExtended;

const mount = async (event: FleetEventExtended) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet, event },
  });
  await flushPromises();

  return wrapper;
};

const chip = (subject: VueWrapper, wday: number) =>
  subject.find(`[data-test="recurrence-weekday-${wday}"] button`);

const save = async (subject: VueWrapper) => {
  await subject.find("form").trigger("submit");
  // vee-validate runs the schema on a timer before it calls the handler.
  await vi.waitFor(() => expect(mutateAsync).toHaveBeenCalled());

  return mutateAsync.mock.calls.at(-1)?.[0].data;
};

describe("FleetEventEditSchedulePage recurrence", () => {
  it("offers the weekdays Monday first for a weekly series", async () => {
    const subject = await mount(series());

    const days = subject
      .findAll('[data-test^="recurrence-weekday-"]')
      .map((day) => day.attributes("data-test"));

    expect(days).toEqual(
      [1, 2, 3, 4, 5, 6, 0].map((wday) => `recurrence-weekday-${wday}`),
    );
  });

  // The server always includes the start day, so the form cannot pretend to
  // take it away.
  it("locks the weekday the series starts on", async () => {
    const subject = await mount(series());

    await chip(subject, 2).trigger("click");

    expect(chip(subject, 2).attributes("disabled")).toBeDefined();
    expect((await save(subject)).recurrenceWeekdays).toEqual([2, 4]);
  });

  it("sends every-N and the chosen weekdays", async () => {
    const subject = await mount(series());

    await chip(subject, 6).trigger("click");
    await chip(subject, 4).trigger("click");

    const data = await save(subject);
    expect(data.recurrenceEvery).toBe(2);
    expect(data.recurrenceWeekdays).toEqual([2, 6]);
  });

  // The start day was implied, not picked, so moving the start takes it along
  // instead of leaving the old day in the pattern.
  it("drops the old start day when the start moves", async () => {
    const subject = await mount(series());

    const startField = subject.findAllComponents(FormDateTime)[0];
    startField.vm.$emit("update:modelValue", "2026-10-07T20:00");
    await flushPromises();

    expect((await save(subject)).recurrenceWeekdays).toEqual([3, 4]);
  });

  // An unknown zone is read as UTC when the times are converted, so the start
  // day must be taken in UTC too, not in the browser's zone.
  it("takes the start day in UTC for a zone the browser cannot resolve", async () => {
    const subject = await mount(
      series({
        startsAt: "2026-10-06T23:30:00Z",
        timezone: "Foo/Bar",
        recurrenceWeekdays: [2],
      }),
    );

    expect(chip(subject, 2).attributes("disabled")).toBeDefined();
  });

  it("hides the weekdays for a series that is not weekly", async () => {
    const subject = await mount(
      series({ recurrenceInterval: "monthly", recurrenceWeekdays: [] }),
    );

    expect(subject.find('[data-test="recurrence-weekdays"]').exists()).toBe(
      false,
    );
    expect((await save(subject)).recurrenceWeekdays).toEqual([]);
  });
});

describe("FleetEventEditSchedulePage times", () => {
  // The browser running the specs may sit in any zone; these hold in all of
  // them because the inputs follow the event's zone, not the browser's.
  it("shows the start as the wall clock in the event's zone", async () => {
    const subject = await mount(
      series({
        recurring: false,
        startsAt: "2026-11-05T01:00:00Z",
        timezone: "America/New_York",
      }),
    );

    const startField = subject.findAllComponents(FormDateTime)[0];
    expect(startField.props("modelValue")).toBe("2026-11-04T20:00");
  });

  it("saves a typed time in the event's zone", async () => {
    const subject = await mount(
      series({
        recurring: false,
        startsAt: "2026-11-05T01:00:00Z",
        timezone: "America/New_York",
      }),
    );

    const startField = subject.findAllComponents(FormDateTime)[0];
    startField.vm.$emit("update:modelValue", "2026-11-06T21:30");
    await flushPromises();

    expect((await save(subject)).startsAt).toBe("2026-11-07T02:30:00.000Z");
  });

  // 00:30 EDT + 2h is 01:30 EST, a wall clock New York shows twice that night.
  it("saves a default end two hours after the start across a DST rollback", async () => {
    const subject = await mount(
      series({
        recurring: false,
        startsAt: "2026-10-31T23:00:00Z",
        endsAt: undefined,
        timezone: "America/New_York",
      }),
    );

    const startField = subject.findAllComponents(FormDateTime)[0];
    startField.vm.$emit("update:modelValue", "2026-11-01T00:30");
    await flushPromises();

    const data = await save(subject);
    expect(data.startsAt).toBe("2026-11-01T04:30:00.000Z");
    expect(data.endsAt).toBe("2026-11-01T06:30:00.000Z");
  });

  // 01:30 happens twice in New York on 1 November 2026. An untouched field
  // must not be re-resolved onto the other one.
  it("keeps an unchanged time in a repeated DST hour", async () => {
    const subject = await mount(
      series({
        recurring: false,
        startsAt: "2026-11-01T06:30:00Z",
        timezone: "America/New_York",
      }),
    );

    expect((await save(subject)).startsAt).toBe("2026-11-01T06:30:00Z");
  });
});
