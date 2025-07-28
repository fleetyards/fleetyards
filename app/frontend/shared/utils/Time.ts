import { intervalToDuration } from "date-fns";
import { zeroPad } from "@/shared/utils/Numbers";

export const toTime = (seconds: number | undefined) => {
  if (!seconds) {
    return "-:-:-";
  }

  const duration = intervalToDuration({ start: 0, end: seconds * 1000 });

  return [
    duration.hours ? zeroPad(duration.hours || 0) : undefined,
    zeroPad(duration.minutes || 0),
    zeroPad(duration.seconds || 0),
  ]
    .filter((item) => item)
    .join(":");
};
