import { settleTarget } from "@/frontend/composables/useScrollSettle";

describe("settleTarget", () => {
  it("picks the nearest stop within reach", () => {
    expect(settleTarget(880, [0, 900, 1800], 200)).toBe(900);
    expect(settleTarget(1650, [0, 900, 1800], 200)).toBe(1800);
  });

  it("leaves the page where it is when no stop is within reach", () => {
    expect(settleTarget(1350, [0, 900, 1800], 200)).toBeUndefined();
  });

  it("settles above as readily as below", () => {
    expect(settleTarget(1000, [0, 900, 1800], 200)).toBe(900);
  });
});
