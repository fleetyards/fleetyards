import { RaffleStatusEnum, useCurrentRaffle } from "@/services/fyApi";

// The raffle the homepage points at: only one that can be entered right now.
// The current-raffle endpoint also answers with the next upcoming or the last
// drawn raffle, and neither belongs on the homepage.
export const useHomeRaffle = () => {
  const { data } = useCurrentRaffle();

  return computed(() =>
    data.value?.status === RaffleStatusEnum.OPEN ? data.value : undefined,
  );
};
