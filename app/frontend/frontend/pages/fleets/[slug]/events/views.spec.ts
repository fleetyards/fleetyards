import { describe, expect, it } from "vitest";
import {
  DEFAULT_EVENT_VIEW,
  eventTabFrom,
  eventViewFrom,
  isEventCalendarView,
  isEventTab,
} from "./views";

describe("eventViewFrom", () => {
  it("takes each of the three list tabs from the query", () => {
    expect(eventViewFrom("upcoming")).toBe("upcoming");
    expect(eventViewFrom("past")).toBe("past");
    expect(eventViewFrom("archived")).toBe("archived");
  });

  it("takes both calendars from the query", () => {
    expect(eventViewFrom("month")).toBe("month");
    expect(eventViewFrom("week")).toBe("week");
  });

  // The page's own address carries no `view`, and a link somebody edited by
  // hand may carry anything at all.
  it("falls back to the default for anything it does not know", () => {
    expect(eventViewFrom(undefined)).toBe(DEFAULT_EVENT_VIEW);
    expect(eventViewFrom("")).toBe(DEFAULT_EVENT_VIEW);
    expect(eventViewFrom("nonsense")).toBe(DEFAULT_EVENT_VIEW);
    expect(eventViewFrom(null)).toBe(DEFAULT_EVENT_VIEW);
  });

  // `route.query` gives an array for a repeated key and does not normalise it,
  // so reading the raw value would match nothing and silently show "upcoming".
  it("reads the first value of a repeated query key", () => {
    expect(eventViewFrom(["archived"])).toBe("archived");
    expect(eventViewFrom(["week", "month"])).toBe("week");
  });

  it("falls back for an empty array", () => {
    expect(eventViewFrom([])).toBe(DEFAULT_EVENT_VIEW);
  });
});

describe("eventTabFrom", () => {
  it("is the view itself on a list tab", () => {
    expect(eventTabFrom("past")).toBe("past");
  });

  // The tab strip is hidden on a calendar, but the list query still has to ask
  // for something, and "upcoming" is what the page opens on.
  it("is the default on a calendar", () => {
    expect(eventTabFrom("month")).toBe(DEFAULT_EVENT_VIEW);
    expect(eventTabFrom("week")).toBe(DEFAULT_EVENT_VIEW);
  });
});

describe("the view guards", () => {
  it("separates the tabs from the calendars", () => {
    expect(isEventTab("upcoming")).toBe(true);
    expect(isEventTab("month")).toBe(false);

    expect(isEventCalendarView("month")).toBe(true);
    expect(isEventCalendarView("upcoming")).toBe(false);
  });
});
