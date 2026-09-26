import type { FleetEvent } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useI18nStore } from "@/shared/stores/i18n";

type RecurrenceFields = Pick<
  FleetEvent,
  "recurrenceInterval" | "recurrenceEvery" | "recurrenceWeekdays"
>;

// Monday first, the way the calendar feed counts a week (WKST=MO), while the
// values stay Ruby's Sunday-first `wday`.
export const WEEKDAYS_MONDAY_FIRST = [1, 2, 3, 4, 5, 6, 0];

export const useRecurrence = () => {
  const { t } = useI18n();
  const i18nStore = useI18nStore();

  // From the browser rather than seven new strings in every locale:
  // 2024-01-07 was a Sunday.
  const weekdayName = (wday: number, width: "short" | "long" = "short") =>
    new Intl.DateTimeFormat(i18nStore.locale, {
      weekday: width,
      timeZone: "UTC",
    }).format(new Date(Date.UTC(2024, 0, 7 + wday)));

  const intervalLabel = (event: RecurrenceFields) => {
    const frequency = event.recurrenceInterval;
    if (!frequency) return "";

    const every = event.recurrenceEvery ?? 1;
    const interval =
      every > 1
        ? t(`labels.fleets.events.recurrence.everyN.${frequency}`, {
            count: every,
          })
        : t(`labels.fleets.events.recurrence.${frequency}`);

    const days = event.recurrenceWeekdays ?? [];
    if (!days.length) return interval;

    const names = WEEKDAYS_MONDAY_FIRST.filter((wday) =>
      days.includes(wday),
    ).map((wday) => weekdayName(wday));

    return t("labels.fleets.events.recurrence.onDays", {
      interval,
      days: new Intl.ListFormat(i18nStore.locale, {
        style: "short",
        type: "conjunction",
      }).format(names),
    });
  };

  return { intervalLabel, weekdayName };
};
