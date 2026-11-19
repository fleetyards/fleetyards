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

// A section gated by a wrapper component rather than by its routes' meta
// provides its flag, so the page headings below it can still show the pill.
export const PAGE_FEATURE: InjectionKey<FeatureFlagName> =
  Symbol("pageFeature");

export const providePageFeature = (feature: FeatureFlagName) => {
  provide(PAGE_FEATURE, feature);
};
