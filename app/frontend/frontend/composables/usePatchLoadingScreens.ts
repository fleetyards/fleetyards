import { useScDataBuilds } from "@/services/fyApi";

// Drawn once per visit, so every part of a page that shows a loading screen
// agrees on which ones it drew.
const draw = Math.random();

// The loading screens of the newest live build, by visit: `pick(0)` is this
// visit's screen, `pick(1)` the next one along, so two places on a page can
// show two different screens when the patch shipped more than one.
export const usePatchLoadingScreens = () => {
  const { data: builds } = useScDataBuilds();

  const screens = computed(
    () =>
      builds.value?.items.find(
        (item) => item.environment.toLowerCase() === "live",
      )?.loadingScreens || [],
  );

  const screenAt = (offset: number) => {
    const list = screens.value;
    if (!list.length) return undefined;

    return list[(Math.floor(draw * list.length) + offset) % list.length];
  };

  const pick = (offset: number, fallback: string) => {
    const screen = screenAt(offset);

    return screen?.largeUrl || screen?.url || fallback;
  };

  return { screens, screenAt, pick };
};
