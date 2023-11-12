import { intervalToDuration } from "date-fns";
import { zeroPad } from "./numbers";

export const toTime = (seconds: number | undefined) => {
  if (!seconds) {
    return "-:-";
  }

  const duration = intervalToDuration({ start: 0, end: seconds * 1000 });

  return `${zeroPad(duration.minutes || 0)}:${zeroPad(duration.seconds || 0)}`;
};
