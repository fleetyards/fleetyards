import { describe, expect, it } from "vitest";
import { RaffleStatusEnum } from "@/services/fyApi";
import { isRaffleOver } from "./raffleStatus";

describe("isRaffleOver", () => {
  it.each([
    RaffleStatusEnum.CLOSED,
    RaffleStatusEnum.DRAWN,
    RaffleStatusEnum.CONCLUDED,
  ])("counts a %s raffle as over", (status) => {
    expect(isRaffleOver({ status })).toBe(true);
  });

  it.each([
    RaffleStatusEnum.DRAFT,
    RaffleStatusEnum.UPCOMING,
    RaffleStatusEnum.OPEN,
  ])("does not count a %s raffle as over", (status) => {
    expect(isRaffleOver({ status })).toBe(false);
  });
});
