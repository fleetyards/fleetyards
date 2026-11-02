import { type FleetEvent } from "@/services/fyApi";

// An hour when the event carries no end, which is what Calendars::IcsBuilder
// assumes too. Handing the library no end at all made it stretch the event
// across the day and spill a second segment onto the next one.
const DEFAULT_DURATION_MS = 60 * 60 * 1000;

// Dates rather than ISO strings: the library reads a string at the clock of
// its own offset and moves it to the reader's zone only on a later options
// change, so events handed over after mount stayed in UTC. A Date is converted
// to the browser's zone as it is read.
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
