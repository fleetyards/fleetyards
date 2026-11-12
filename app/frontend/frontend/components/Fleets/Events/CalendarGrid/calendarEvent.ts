import { type FleetEvent, type GameEvent } from "@/services/fyApi";

// An hour when the event carries no end, which is what Calendars::IcsBuilder
// assumes too. Handing the library no end at all made it stretch the event
// across the day and spill a second segment onto the next one.
const DEFAULT_DURATION_MS = 60 * 60 * 1000;

// Dates rather than ISO strings: the library reads a string at the clock of
// its own offset and moves it to the reader's zone only on a later options
// change, which events set after mount never get. A Date is converted to the
// browser's zone as it is read.
export const buildCalendarEvent = (event: FleetEvent) => {
  const start = new Date(event.startsAt);

  return {
    id: event.slug,
    start,
    end: event.endsAt
      ? new Date(event.endsAt)
      : new Date(start.getTime() + DEFAULT_DURATION_MS),
    title: event.title,
    extendedProps: { fleetEvent: event },
  };
};

export const buildGameCalendarEvent = (event: GameEvent) => {
  const start = new Date(event.startsAt);

  return {
    id: `game-${event.id}`,
    start,
    end: event.endsAt
      ? new Date(event.endsAt)
      : new Date(start.getTime() + DEFAULT_DURATION_MS),
    title: event.title,
    extendedProps: { gameEvent: event },
  };
};
