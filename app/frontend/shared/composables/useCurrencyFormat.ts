import { useI18nStore } from "@/shared/stores/i18n";

export const useCurrencyFormat = () => {
  const i18nStore = useI18nStore();

  const formatCents = (amountCents: number, currency = "EUR") => {
    const locale = i18nStore.locale || "en";
    return new Intl.NumberFormat(locale, {
      style: "currency",
      currency,
    }).format(amountCents / 100);
  };

  return { formatCents };
};
