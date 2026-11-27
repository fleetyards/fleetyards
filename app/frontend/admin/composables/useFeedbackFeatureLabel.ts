import { useI18n } from "@/shared/composables/useI18n";
import { featureLabel } from "@/shared/utils/BetaFeatures";
import { type Feedback } from "@/services/fyAdminApi";

export const useFeedbackFeatureLabel = () => {
  const { t } = useI18n();

  return (feedback: Pick<Feedback, "featureName">) =>
    feedback.featureName
      ? featureLabel(feedback.featureName)
      : t("feedback.admin.general");
};
