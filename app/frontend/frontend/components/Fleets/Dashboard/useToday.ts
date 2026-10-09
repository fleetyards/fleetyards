import { startOfDay } from "date-fns";

// Checked once a minute: often enough that a dashboard left open overnight
// moves on to the new day, cheap enough to leave running.
const TICK_MS = 60_000;

/**
 * The start of today, kept current. A window computed from `new Date()` once
 * is frozen at the moment the page opened, so a refetch the next morning would
 * still ask for yesterday.
 */
export const useToday = () => {
  const today = ref(startOfDay(new Date()));

  let timer: ReturnType<typeof setInterval> | undefined;

  onMounted(() => {
    timer = setInterval(() => {
      const now = startOfDay(new Date());
      if (now.getTime() !== today.value.getTime()) today.value = now;
    }, TICK_MS);
  });

  onUnmounted(() => clearInterval(timer));

  return today;
};
