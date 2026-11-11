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
