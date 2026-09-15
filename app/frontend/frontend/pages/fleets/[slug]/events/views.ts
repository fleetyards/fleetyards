/*
 * The five views of a fleet's events, as one page's query rather than five
 * pages: three narrowings of the list, and two calendars.
 *
 * The choice rides in `?view=` so each of them can be linked to - "the fleet's
 * archived events" is an address somebody can send - and switching keeps the
 * page rather than rebuilding it, the same reasoning the contracts board's
 * views carry.
 */
export type EventTab = "upcoming" | "past" | "archived";

export type EventCalendarView = "month" | "week";

export type EventView = EventTab | EventCalendarView;

export const EVENT_TABS: EventTab[] = ["upcoming", "past", "archived"];

export const EVENT_CALENDAR_VIEWS: EventCalendarView[] = ["month", "week"];

export const DEFAULT_EVENT_VIEW: EventTab = "upcoming";

export const isEventTab = (value: unknown): value is EventTab =>
  EVENT_TABS.includes(value as EventTab);

export const isEventCalendarView = (
  value: unknown,
): value is EventCalendarView =>
  EVENT_CALENDAR_VIEWS.includes(value as EventCalendarView);

/*
 * `route.query` hands back a string, an array of them, or nothing, and none of
 * the three may leave the page showing something nobody asked for. A repeated
 * `?view=` is the one that bites: it arrives as an array, which matches no key
 * at all, so a link carrying one would have fallen back to "upcoming" without
 * saying so.
 */
export const eventViewFrom = (value: unknown): EventView => {
  const first = Array.isArray(value) ? value[0] : value;

  if (isEventCalendarView(first)) return first;

  return isEventTab(first) ? first : DEFAULT_EVENT_VIEW;
};

// Which of the three list tabs is showing. A calendar is not one of them, and
// the tab strip it belongs to is hidden there, so the default stands in.
export const eventTabFrom = (view: EventView): EventTab =>
  isEventTab(view) ? view : DEFAULT_EVENT_VIEW;

/*
 * The tab to remember, so leaving a calendar returns to the list the reader
 * opened it from. A calendar remembers nothing - it has no tab of its own, and
 * `eventTabFrom` reports the default there, so feeding that back in is what
 * loses the tab: open the calendar from "archived" and you come back to
 * "upcoming". Hence the view, not the tab.
 */
export const rememberedTab = (view: EventView, previous: EventTab): EventTab =>
  isEventCalendarView(view) ? previous : view;
