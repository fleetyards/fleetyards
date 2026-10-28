import { type Raffle, RaffleStatusEnum } from "@/services/fyApi";

const ENDED_STATUSES: RaffleStatusEnum[] = [
  RaffleStatusEnum.CLOSED,
  RaffleStatusEnum.DRAWN,
  RaffleStatusEnum.CONCLUDED,
];

export const isRaffleOver = (raffle: Pick<Raffle, "status">) =>
  ENDED_STATUSES.includes(raffle.status);
