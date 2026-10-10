import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { computed, ref, type Ref } from "vue";

type Call = {
  range: Ref<{ from: string; to: string }>;
  enabled: Ref<boolean>;
};

const calls: Call[] = [];

vi.mock("@/services/fyApi", () => ({
  useFleetCalendar: (
    _slug: unknown,
    range: Ref<{ from: string; to: string }>,
    options: { query: { enabled: Ref<boolean> } },
  ) => {
    calls.push({ range, enabled: options.query.enabled });

    return { data: computed(() => ({ items: [] })), isLoading: ref(false) };
  },
}));

const { useDashboardCalendar } = await import("./useDashboardCalendar");

// A Wednesday: this week runs Monday the 5th to Sunday the 11th.
const NOW = new Date(2026, 9, 7, 12, 0);

const day = (iso: string) => {
  const date = new Date(iso);

  return `${date.getMonth() + 1}/${date.getDate()}`;
};

const asking = () => calls.filter(({ enabled }) => enabled.value);

describe("useDashboardCalendar", () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(NOW);
    calls.length = 0;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // From the Sunday before this week -- a day earlier than it shows, for what
  // runs past midnight -- to two weeks out.
  it("asks once for the upcoming two weeks and this week together", () => {
    useDashboardCalendar("maru", true);

    expect(asking()).toHaveLength(1);
    expect(day(asking()[0].range.value.from)).toBe("10/4");
    expect(day(asking()[0].range.value.to)).toBe("10/21");
  });

  it("asks nothing more when the week view reports this week", () => {
    const calendar = useDashboardCalendar("maru", true);

    calendar.showWeek({
      start: new Date(2026, 9, 5),
      end: new Date(2026, 9, 12),
    });

    expect(asking()).toHaveLength(1);
  });

  it("asks nothing more for next week, which the upcoming two already hold", () => {
    const calendar = useDashboardCalendar("maru", true);

    calendar.showWeek({
      start: new Date(2026, 9, 12),
      end: new Date(2026, 9, 19),
    });

    expect(asking()).toHaveLength(1);
  });

  // Paging far ahead fetches that week, not every week in between.
  it("asks for a week paged to on its own", () => {
    const calendar = useDashboardCalendar("maru", true);

    calendar.showWeek({
      start: new Date(2026, 10, 2),
      end: new Date(2026, 10, 9),
    });

    expect(asking()).toHaveLength(2);
    expect(day(asking()[1].range.value.from)).toBe("11/1");
    expect(day(asking()[1].range.value.to)).toBe("11/9");
    expect(day(asking()[0].range.value.from)).toBe("10/4");
  });

  it("asks nothing while the fleet has no events", () => {
    useDashboardCalendar("maru", false);

    expect(asking()).toHaveLength(0);
  });
});
