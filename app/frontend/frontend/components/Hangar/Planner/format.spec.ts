import { describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { usePlanMoney } from "./format";

describe("Hangar/Planner/format", () => {
  setActivePinia(createPinia());
  const { net } = usePlanMoney();

  it("reads a fully negative net as credit, smallest first", () => {
    expect(net(-985, -545)).toBe("$545 – $985 credit");
    expect(net(-985, -985)).toBe("$985 credit");
  });

  it("keeps a net that can still cost something as a range", () => {
    expect(net(100, 300)).toBe("$100 – $300");
    expect(net(0, 0)).toBe("$0.00");
    expect(net(-200, 300)).toContain("$300");
  });
});
