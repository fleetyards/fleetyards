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
  role?: string | null;
  candidates?: unknown[];
}

const ROLE_RANK: Record<string, number> = { captain: 1, pilot: 2 };

// The lead first, then the captain and the pilot, then the seats someone is
// listed for, then the open ones -- each group keeping the order it came in.
export const sortByFilled = <T extends FillableSlot>(slots: T[]): T[] => {
  const rank = (slot: T) => {
    if (slot.lead) return 0;
    if (slot.role && ROLE_RANK[slot.role]) return ROLE_RANK[slot.role];

    return slot.candidates?.length ? 3 : 4;
  };

  return [...slots].sort((a, b) => rank(a) - rank(b));
};
