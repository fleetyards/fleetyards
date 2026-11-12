import type { MaybeRefOrGetter } from "vue";
import { useScDataBuilds } from "@/services/fyApi";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";

// Drawn once per visit, so every part of a page that shows a loading screen
// agrees on which ones it drew.
const draw = Math.random();

// The loading screens of an environment's newest build -- by default the
// source being read, live or the preview the reader switched to -- by visit:
// `pick(0)` is this visit's screen, `pick(1)` the next one along, so two places
// on a page can show two different screens when the patch shipped more than
// one.
//
// The newest build that has any: a build loaded since the screens were last
// imported has none yet, and the one before it is the same patch more often
// than not.
export const usePatchLoadingScreens = (
  forEnvironment?: MaybeRefOrGetter<string | undefined>,
) => {
  const { data: builds } = useScDataBuilds();

  const sourceStore = useScDataSourceStore();

  const environment = computed(
    () =>
      toValue(forEnvironment)?.toLowerCase() ||
      sourceStore.selected?.environment.toLowerCase() ||
      "live",
  );

  const ofEnvironment = computed(
    () =>
      builds.value?.items.filter(
        (item) => item.environment.toLowerCase() === environment.value,
      ) || [],
  );

  const build = computed(() => ofEnvironment.value[0]);

  const screens = computed(
    () =>
      ofEnvironment.value.find((item) => item.loadingScreens.length > 0)
        ?.loadingScreens || [],
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

  return { build, screens, screenAt, pick };
};
