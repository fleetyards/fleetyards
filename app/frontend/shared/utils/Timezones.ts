import { formatInTimeZone, fromZonedTime } from "date-fns-tz";

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

// The reverse of wallClockToIso: an instant as the wall clock in `zone`, in the
// shape a `datetime-local` input takes.
export const isoToWallClock = (
  iso: string | null | undefined,
  zone: string | null | undefined,
): string => {
  if (!iso) return "";
  const date = new Date(iso);
  if (isNaN(date.getTime())) return "";
  return formatInTimeZone(date, resolveTimezone(zone), DATETIME_LOCAL_FORMAT);
};

// Formats an instant as the wall clock in `zone`.
export const formatInZone = (
  iso: string | null | undefined,
  zone: string | null | undefined,
  pattern: string,
): string => {
  if (!iso) return "";
  const date = new Date(iso);
  if (isNaN(date.getTime())) return "";
  return formatInTimeZone(date, resolveTimezone(zone), pattern);
};

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
