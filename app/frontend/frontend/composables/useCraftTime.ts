import { useI18n } from "@/shared/composables/useI18n";

/**
 * Craft time, as the game states it: seconds, from 10 to just over two hours.
 *
 * Rendered as the largest two units that carry information rather than as a
 * bare count of seconds -- "16m", "2h 31m", "10s". The game itself partitions
 * the value into days/hours/minutes/seconds and nothing in the current build
 * takes a day, so the top unit here is the hour.
 */
export const useCraftTime = () => {
  const { t } = useI18n();

  const format = (seconds?: number | null) => {
    if (seconds === undefined || seconds === null) return undefined;

    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const rest = seconds % 60;

    const parts: string[] = [];
    if (hours > 0)
      parts.push(t("labels.blueprint.duration.hours", { count: hours }));
    if (minutes > 0)
      parts.push(t("labels.blueprint.duration.minutes", { count: minutes }));
    // Only where it is the whole story: "2h 31m 12s" is noise, "45s" is not.
    if (rest > 0 && hours === 0 && minutes === 0) {
      parts.push(t("labels.blueprint.duration.seconds", { count: rest }));
    }

    return parts.join(" ");
  };

  return { format };
};
