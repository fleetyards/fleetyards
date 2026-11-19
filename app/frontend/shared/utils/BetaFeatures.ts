import { provide, type InjectionKey, type Ref } from "vue";
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

// The first flag of a gate that is beta, which feedback about it is filed
// under.
export const betaFeatureOf = (
  feature: FeatureFlagName | FeatureFlagName[] | undefined | null,
  betaFeatures: readonly string[] | undefined,
): FeatureFlagName | undefined =>
  feature
    ? [feature].flat().find((entry) => betaFeatures?.includes(entry))
    : undefined;

export type OpenFeedback = (feature?: FeatureFlagName) => void;

// Provided by an app that can take feedback, and only while it can: a pill
// without it explains itself but opens nothing.
export const OPEN_FEEDBACK: InjectionKey<Ref<OpenFeedback | undefined>> =
  Symbol("openFeedback");

export const featureLabel = (feature: string) => feature.replace(/[_-]/g, " ");
