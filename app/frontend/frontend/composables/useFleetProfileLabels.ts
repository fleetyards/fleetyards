import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetActivityEnum,
  FleetAlignmentEnum,
  FleetCommitmentEnum,
  FleetLanguageEnum,
  type FilterOption,
} from "@/services/fyApi";

// Language names come from the browser rather than from a translation per
// language and locale: RSI lists 184 of them.
export const useFleetProfileLabels = () => {
  const { t, currentLocale } = useI18n();

  const languageNames = computed(() => {
    try {
      return new Intl.DisplayNames([currentLocale(), "en"], {
        type: "language",
      });
    } catch {
      return undefined;
    }
  });

  const activityLabel = (activity?: string | null) =>
    activity ? t(`labels.fleet.activities.${activity}`) : undefined;

  const alignmentLabel = (alignment?: string | null) =>
    alignment ? t(`labels.fleet.alignments.${alignment}`) : undefined;

  const commitmentLabel = (commitment?: string | null) =>
    commitment ? t(`labels.fleet.commitments.${commitment}`) : undefined;

  const languageLabel = (language?: string | null) => {
    if (!language) return undefined;

    return languageNames.value?.of(language) ?? language;
  };

  const activityOptions = computed<FilterOption[]>(() =>
    Object.values(FleetActivityEnum).map((value) => ({
      value,
      label: activityLabel(value) ?? value,
    })),
  );

  const alignmentOptions = computed<FilterOption[]>(() =>
    Object.values(FleetAlignmentEnum).map((value) => ({
      value,
      label: alignmentLabel(value) ?? value,
    })),
  );

  const commitmentOptions = computed<FilterOption[]>(() =>
    Object.values(FleetCommitmentEnum).map((value) => ({
      value,
      label: commitmentLabel(value) ?? value,
    })),
  );

  const languageOptions = computed<FilterOption[]>(() =>
    Object.values(FleetLanguageEnum).map((value) => ({
      value,
      label: languageLabel(value) ?? value,
    })),
  );

  return {
    activityLabel,
    alignmentLabel,
    commitmentLabel,
    languageLabel,
    activityOptions,
    alignmentOptions,
    commitmentOptions,
    languageOptions,
  };
};
