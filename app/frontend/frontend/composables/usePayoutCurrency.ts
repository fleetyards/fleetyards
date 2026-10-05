import type { ComputedRef, InjectionKey, MaybeRefOrGetter } from "vue";
import { TourCurrencyEnum } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const PAYOUT_CURRENCY: InjectionKey<ComputedRef<TourCurrencyEnum>> =
  Symbol("payoutCurrency");

// Only a tour picks its currency; an event's or a contract's ledger is always
// counted in aUEC.
export const providePayoutCurrency = (
  currency: MaybeRefOrGetter<TourCurrencyEnum | undefined>,
) => {
  provide(
    PAYOUT_CURRENCY,
    computed(() => toValue(currency) ?? TourCurrencyEnum.AUEC),
  );
};

// A modal is mounted outside the ledger's tree and cannot inject, so it is
// handed the currency instead.
export const usePayoutCurrency = (
  currency?: MaybeRefOrGetter<TourCurrencyEnum | undefined>,
) => {
  const injected = inject(PAYOUT_CURRENCY, undefined);
  const { t, toUEC, currentLocale } = useI18n();

  const current = computed(
    () => toValue(currency) ?? injected?.value ?? TourCurrencyEnum.AUEC,
  );

  const isUEC = computed(() => current.value === TourCurrencyEnum.AUEC);

  const currencyLabel = computed(() =>
    isUEC.value ? t("number.units.uec") : current.value.toUpperCase(),
  );

  // Returns markup, like toUEC: the unit is dimmed the same way so a ledger
  // reads alike whichever currency it is in.
  const formatAmount = (value?: number) => {
    if (isUEC.value) {
      return toUEC(value);
    }

    if (!value) {
      return "-";
    }

    return new Intl.NumberFormat(currentLocale(), {
      style: "currency",
      currency: current.value.toUpperCase(),
    })
      .formatToParts(value)
      .map((part) =>
        part.type === "currency"
          ? `<span class="text-muted">${part.value}</span>`
          : part.value,
      )
      .join("");
  };

  return { currency: current, currencyLabel, formatAmount };
};

export const usePayoutCurrencyOptions = () => {
  const { t, currentLocale } = useI18n();

  return computed(() => {
    const names = new Intl.DisplayNames(currentLocale(), { type: "currency" });

    const real = Object.values(TourCurrencyEnum)
      .filter((value) => value !== TourCurrencyEnum.AUEC)
      .map((value) => ({
        value,
        label: `${value.toUpperCase()} · ${names.of(value.toUpperCase())}`,
      }))
      .sort((a, b) => a.label.localeCompare(b.label));

    // The game's own currency leads: it is what almost every tour is counted
    // in. Callers pass `unsorted` so the select keeps this order.
    return [
      { value: TourCurrencyEnum.AUEC, label: t("number.units.uec") },
      ...real,
    ];
  });
};
