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

// The zone abbreviation in force at `iso`: the option labels carry a fixed one,
// and "London (GMT)" beside a summer time names the wrong offset.
const abbreviationAt = (iso: string, zone: string | null | undefined) =>
  new Intl.DateTimeFormat("en-US", {
    timeZone: resolveTimezone(zone),
    timeZoneName: "short",
  })
    .formatToParts(new Date(iso))
    .find((part) => part.type === "timeZoneName")?.value ?? "";

// The organiser's times beside times shown in the viewer's zone, e.g.
// "Wed 20:00–22:00 New York (EST)" — or null when every clock reads the same,
// where a second copy would say nothing new. Start and end are compared
// separately because a DST change between them can make them disagree, and
// then each carries its own offset.
export const organiserTimeHint = (
  startIso: string | null | undefined,
  endIso: string | null | undefined,
  eventZone: string | null | undefined,
  viewerZone = browserTimezone(),
): string | null => {
  const pattern = "EEE HH:mm";
  const start = formatInZone(startIso, eventZone, pattern);
  if (!startIso || !start) return null;

  const end = endIso ? formatInZone(endIso, eventZone, pattern) : "";
  const same = (iso: string, there: string) =>
    there === formatInZone(iso, viewerZone, pattern);
  if (same(startIso, start) && (!end || same(endIso as string, end))) {
    return null;
  }

  const name = timezoneLabel(eventZone).replace(/\s*\(.*\)$/, "");
  const startAbbr = abbreviationAt(startIso, eventZone);
  const endAbbr = end ? abbreviationAt(endIso as string, eventZone) : startAbbr;
  const endLabel =
    end && end.slice(0, 3) === start.slice(0, 3) ? end.slice(4) : end;

  if (end && startAbbr !== endAbbr) {
    return `${start} ${startAbbr}–${endLabel} ${endAbbr} ${name}`;
  }
  const range = end ? `${start}–${endLabel}` : start;
  return startAbbr && startAbbr !== name
    ? `${range} ${name} (${startAbbr})`
    : `${range} ${name}`;
};
