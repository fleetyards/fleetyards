import { useI18n } from "@/shared/composables/useI18n";

const present = (value?: number | null): value is number =>
  value !== undefined && value !== null && Number.isFinite(value);

// Formatters that return `undefined` for missing data instead of a placeholder,
// so a compare cell can tell "no value" apart from a real one. `toNumber` renders
// everything falsy as "N/A" — in a matrix an em dash reads better, and a genuine
// zero has to stay a zero.
export const useCompareFormat = () => {
  const { toNumber, toUEC, toDollar } = useI18n();

  const number = (value?: number | null, units = "") => {
    if (!present(value)) {
      return undefined;
    }

    if (value === 0) {
      return "0";
    }

    return String(toNumber(value, units));
  };

  const rounded = (value?: number | null, units = "") =>
    present(value) ? number(Math.round(value), units) : undefined;

  const uec = (value?: number) => (value ? toUEC(value) : undefined);

  const dollar = (value?: number) => (value ? toDollar(value) : undefined);

  const percent = (value?: number | null) =>
    present(value) ? `${Math.round(value * 100)}%` : undefined;

  const text = (value?: string | null) => value || undefined;

  return { number, rounded, uec, dollar, percent, text };
};
