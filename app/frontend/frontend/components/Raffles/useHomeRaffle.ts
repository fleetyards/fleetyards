import { RaffleStatusEnum, useCurrentRaffle } from "@/services/fyApi";

// The raffle the homepage points at: the current one while it can still be
// entered or is about to open. A drawn raffle is news on its own page, not
// on the homepage.
export const useHomeRaffle = () => {
  const { data } = useCurrentRaffle();

  return computed(() => {
    const raffle = data.value;
    if (!raffle) return undefined;

    const shown: RaffleStatusEnum[] = [
      RaffleStatusEnum.OPEN,
      RaffleStatusEnum.UPCOMING,
    ];

    return shown.includes(raffle.status) ? raffle : undefined;
  });
};
