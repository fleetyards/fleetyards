declare module "@event-calendar/core" {
  // Library has no first-party TS types; we declare just the surface we use.
  export const DayGrid: unknown;
  export const TimeGrid: unknown;
  export const Interaction: unknown;
  export const List: unknown;

  export type EventCalendarInstance = {
    setOption: (name: string, value: unknown) => EventCalendarInstance;
    getOption: (name: string) => unknown;
    next: () => EventCalendarInstance;
    prev: () => EventCalendarInstance;
    refetchEvents: () => EventCalendarInstance;
  };

  export function createCalendar(
    target: HTMLElement,
    plugins: unknown[],
    options: Record<string, unknown>,
  ): EventCalendarInstance;

  export function destroyCalendar(instance: EventCalendarInstance): void;
}

declare module "@event-calendar/core/index.css";
