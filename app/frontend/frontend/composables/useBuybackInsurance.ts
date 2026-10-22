import { useI18n } from "@/shared/composables/useI18n";

type Insured = {
  lifetimeInsurance: boolean;
  insuranceMonths?: number | null;
  insuranceKnown: boolean;
};

// Insurance is read from a pledge's detail page, so a pledge whose details were
// never synced says it is unknown rather than reading as uninsured.
export const useBuybackInsurance = () => {
  const { t } = useI18n();

  return (pledge: Insured) => {
    if (pledge.lifetimeInsurance) return t("labels.buybacks.lifetimeInsurance");
    if (pledge.insuranceMonths) {
      return t("labels.buybacks.insuranceMonths", {
        count: pledge.insuranceMonths,
      });
    }
    if (pledge.insuranceKnown) return t("labels.buybacks.noInsurance");

    return t("labels.buybacks.insuranceUnknown");
  };
};
