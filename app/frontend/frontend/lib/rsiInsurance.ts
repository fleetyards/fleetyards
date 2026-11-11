const MONTHS_INSURANCE = /^(\d+)\s+Months?\s+Insurance$/i;

const LIFETIME_INSURANCE = /^Lifetime\s+Insurance$/i;

export type RSIInsurance = {
  lifetimeInsurance: boolean;
  insuranceMonths?: number;
};

// The insurance a pledge lists among its items, as "Lifetime Insurance" or
// "120 Month Insurance". A package of several ships lists one per ship; the
// longest is the one worth naming. None listed is none.
export const readInsurance = (labels: string[]): RSIInsurance => {
  const lifetimeInsurance = labels.some((label) =>
    LIFETIME_INSURANCE.test(label),
  );
  const months = labels
    .map((label) =>
      Number.parseInt(label.match(MONTHS_INSURANCE)?.[1] || "", 10),
    )
    .filter((value) => !Number.isNaN(value));

  return {
    lifetimeInsurance,
    insuranceMonths:
      lifetimeInsurance || months.length === 0
        ? undefined
        : Math.max(...months),
  };
};
