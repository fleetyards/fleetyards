import { provide, type InjectionKey } from "vue";
import type { FeatureFlagName } from "@/services/fyApi";

// A stacked gate is beta as soon as one of its flags is.
export const isBetaFeature = (
  feature: FeatureFlagName | FeatureFlagName[] | undefined | null,
  betaFeatures: readonly string[] | undefined,
): boolean => {
  if (!feature || !betaFeatures?.length) {
    return false;
  }

  return [feature].flat().some((entry) => betaFeatures.includes(entry));
};

// A section gated by a wrapper component rather than by its routes' meta
// provides its flag, so the page headings below it can still show the pill.
export const PAGE_FEATURE: InjectionKey<FeatureFlagName> =
  Symbol("pageFeature");

export const providePageFeature = (feature: FeatureFlagName) => {
  provide(PAGE_FEATURE, feature);
};
