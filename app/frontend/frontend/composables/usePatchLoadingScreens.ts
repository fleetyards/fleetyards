import type { MaybeRefOrGetter } from "vue";
import { useScDataBuilds } from "@/services/fyApi";

// Drawn once per visit, so every part of a page that shows a loading screen
// agrees on which ones it drew.
const draw = Math.random();

// The loading screens of an environment's newest build, by visit: `pick(0)` is
// this visit's screen, `pick(1)` the next one along, so two places on a page
// can show two different screens when the patch shipped more than one.
//
// The newest build that has any: a build loaded since the screens were last
// imported has none yet, and the one before it is the same patch more often
// than not.
export const usePatchLoadingScreens = (
  environment: MaybeRefOrGetter<string> = "live",
) => {
  const { data: builds } = useScDataBuilds();

  const live = computed(() =>
    builds.value?.items.find(
      (item) => item.environment.toLowerCase() === toValue(environment),
    ),
  );

  const screens = computed(
    () =>
      builds.value?.items.find(
        (item) =>
          item.environment.toLowerCase() === toValue(environment) &&
          item.loadingScreens.length > 0,
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

  return { live, screens, screenAt, pick };
};
