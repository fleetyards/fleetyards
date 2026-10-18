import type { MaybeRefOrGetter } from "vue";
import type { Model } from "@/services/fyApi";

type PlannedModel = Pick<Model, "erkulIdentifier" | "scIdentifier">;

/**
 * The ship on the sites a loadout can be planned on and linked from: Erkul's
 * DPS calculator, which falls back to the game's identifier where it names the
 * ship no differently, and SPViewer.
 */
export const useLoadoutPlanners = (
  model: MaybeRefOrGetter<PlannedModel | undefined>,
) => {
  const erkulUrl = computed(() => {
    const identifier =
      toValue(model)?.erkulIdentifier || toValue(model)?.scIdentifier;

    return identifier
      ? `https://www.erkul.games/ship/${identifier}`
      : undefined;
  });

  const spviewerUrl = computed(() => {
    const identifier = toValue(model)?.scIdentifier;

    return identifier
      ? `https://www.spviewer.eu/performance?ship=${identifier}`
      : undefined;
  });

  return { erkulUrl, spviewerUrl };
};
