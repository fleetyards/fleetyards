import { provide, type InjectionKey } from "vue";
import { BetaFeatureFlagName, type FeatureFlagName } from "@/services/fyApi";

const BETA_FEATURES = new Set<string>(Object.values(BetaFeatureFlagName));

// A stacked gate is beta as soon as one of its flags is.
export const isBetaFeature = (
  feature: FeatureFlagName | FeatureFlagName[] | undefined | null,
): boolean => {
  if (!feature) {
    return false;
  }

  return [feature].flat().some((entry) => BETA_FEATURES.has(entry));
};

// The flags of the controls a toolbar is showing, for the one pill that
// stands in for icon buttons too small to carry one each.
export const shownFeatures = (
  shown: Partial<Record<FeatureFlagName, boolean>>,
): FeatureFlagName[] =>
  (Object.keys(shown) as FeatureFlagName[]).filter((feature) => shown[feature]);

// A section gated by a wrapper component rather than by its routes' meta
// provides its flag, so the page headings below it can still show the pill.
export const PAGE_FEATURE: InjectionKey<FeatureFlagName> =
  Symbol("pageFeature");

export const providePageFeature = (feature: FeatureFlagName) => {
  provide(PAGE_FEATURE, feature);
};
