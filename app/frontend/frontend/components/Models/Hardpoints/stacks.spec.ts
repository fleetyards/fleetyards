import { describe, expect, it } from "vitest";
import type { Hardpoint } from "@/services/fyApi";
import { groupIntoStacks } from "./stacks";

const turret = (id: string, componentId: string, groupKey = "tractor-beam") =>
  ({ id, groupKey, component: { id: componentId } }) as unknown as Hardpoint;

describe("groupIntoStacks", () => {
  it("stacks hardpoints with the same contents and the same part", () => {
    const stacks = groupIntoStacks([
      turret("left", "remote"),
      turret("right", "remote"),
    ]);

    expect(Object.values(stacks).map((stack) => stack.length)).toEqual([2]);
  });

  it("keeps apart different parts that carry the same contents", () => {
    const stacks = groupIntoStacks([
      turret("rail-01", "rail-turret"),
      turret("rail-02", "interior-turret"),
      turret("nose", "nose-turret"),
    ]);

    expect(Object.values(stacks).map((stack) => stack.length)).toEqual([
      1, 1, 1,
    ]);
  });
});
