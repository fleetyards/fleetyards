import { useI18n } from "@/shared/composables/useI18n";

interface TitledSlot {
  title: string;
  lead?: boolean;
}

// A team's lead seat is named by the app, in the reader's language; every
// other seat by whoever made it.
export const useSlotTitle = () => {
  const { t } = useI18n();

  return (slot: TitledSlot) =>
    slot.lead ? t("labels.fleet.squadrons.flights.lead") : slot.title;
};

interface FillableSlot {
  lead?: boolean;
  candidates?: unknown[];
}

// The lead first, then the seats someone is listed for, then the open ones --
// each group keeping the order it came in.
export const sortByFilled = <T extends FillableSlot>(slots: T[]): T[] => {
  const rank = (slot: T) => (slot.lead ? 0 : slot.candidates?.length ? 1 : 2);

  return [...slots].sort((a, b) => rank(a) - rank(b));
};
