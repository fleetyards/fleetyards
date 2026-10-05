import { useI18n } from "@/shared/composables/useI18n";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

export const useFeatureState = () => {
  const { t } = useI18n();

  const stateVariant = (state: string): `${PillVariantsEnum}` => {
    switch (state) {
      case "on":
        return PillVariantsEnum.SUCCESS;
      case "off":
        return PillVariantsEnum.DANGER;
      case "conditional":
        return PillVariantsEnum.WARNING;
      default:
        return PillVariantsEnum.DEFAULT;
    }
  };

  const stateLabel = (state: string) => {
    switch (state) {
      case "on":
        return t("labels.features.stateOn");
      case "off":
        return t("labels.features.stateOff");
      case "conditional":
        return t("labels.features.stateConditional");
      default:
        return state;
    }
  };

  return { stateVariant, stateLabel };
};
