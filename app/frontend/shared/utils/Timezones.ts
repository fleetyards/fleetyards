import { TZDate } from "@date-fns/tz";
import { format } from "date-fns";
import { fromZonedTime } from "date-fns-tz";

type TimezoneOption = { value: string; label: string };

// The value a `datetime-local` input reads and writes.
export const DATETIME_LOCAL_FORMAT = "yyyy-MM-dd'T'HH:mm";

// An event's zone falls back to UTC when it is missing or not a name the
// browser knows, the same fallback the server uses for recurrence.
export const resolveTimezone = (zone: string | null | undefined): string => {
  if (!zone) return "UTC";
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: zone });
    return zone;
  } catch {
    return "UTC";
  }
};

// A wall-clock value from a `datetime-local` input, read in `zone` rather than
// in the browser's zone: 20:00 picked for America/New_York is 20:00 there,
// whoever's browser it is typed into.
export const wallClockToIso = (
  value: string | null | undefined,
  zone: string | null | undefined,
): string | null => {
  if (!value) return null;
  const date = fromZonedTime(value, resolveTimezone(zone));
  return isNaN(date.getTime()) ? null : date.toISOString();
};

// Formats an instant as the wall clock in `zone`. A TZDate rather than
// date-fns-tz's formatInTimeZone, which goes through a browser-local Date: a
// wall clock in the browser's own DST gap comes out an hour late.
export const formatInZone = (
  iso: string | null | undefined,
  zone: string | null | undefined,
  pattern: string,
): string => {
  if (!iso) return "";
  const date = new Date(iso);
  if (isNaN(date.getTime())) return "";
  return format(new TZDate(date, resolveTimezone(zone)), pattern);
};

// The reverse of wallClockToIso: an instant as the wall clock in `zone`, in the
// shape a `datetime-local` input takes.
export const isoToWallClock = (
  iso: string | null | undefined,
  zone: string | null | undefined,
): string => formatInZone(iso, zone, DATETIME_LOCAL_FORMAT);

// The browser's own zone, for labelling times shown in it.
export const browserTimezone = (): string =>
  Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";

// Curated list of common IANA timezones used in event scheduling.
// Kept short on purpose — covers the regions Star Citizen fleets typically pull
// members from. Add more if a fleet asks for one.
export const TIMEZONE_OPTIONS: TimezoneOption[] = [
  { value: "UTC", label: "UTC" },
  { value: "America/Los_Angeles", label: "Los Angeles (PT)" },
  { value: "America/Denver", label: "Denver (MT)" },
  { value: "America/Chicago", label: "Chicago (CT)" },
  { value: "America/New_York", label: "New York (ET)" },
  { value: "America/Sao_Paulo", label: "São Paulo" },
  { value: "Europe/London", label: "London (GMT)" },
  { value: "Europe/Berlin", label: "Berlin / Paris (CET)" },
  { value: "Europe/Helsinki", label: "Helsinki (EET)" },
  { value: "Europe/Moscow", label: "Moscow" },
  { value: "Africa/Johannesburg", label: "Johannesburg" },
  { value: "Asia/Dubai", label: "Dubai" },
  { value: "Asia/Kolkata", label: "Kolkata" },
  { value: "Asia/Singapore", label: "Singapore" },
  { value: "Asia/Tokyo", label: "Tokyo" },
  { value: "Australia/Perth", label: "Perth" },
  { value: "Australia/Sydney", label: "Sydney" },
  { value: "Pacific/Auckland", label: "Auckland" },
];

// The name a zone is offered under in the event form, or the zone itself.
export const timezoneLabel = (zone: string | null | undefined): string => {
  const resolved = resolveTimezone(zone);
  return (
    TIMEZONE_OPTIONS.find((option) => option.value === resolved)?.label ??
    resolved
  );
};

// The organiser's time beside a time shown in the viewer's zone, e.g.
// "Wed 20:00 New York (ET)" — or null when both clocks read the same, where a
// second copy of the time would say nothing new.
export const organiserTimeHint = (
  iso: string | null | undefined,
  eventZone: string | null | undefined,
  viewerZone = browserTimezone(),
): string | null => {
  const pattern = "EEE HH:mm";
  const there = formatInZone(iso, eventZone, pattern);
  if (!there || there === formatInZone(iso, viewerZone, pattern)) return null;
  return `${there} ${timezoneLabel(eventZone)}`;
};
