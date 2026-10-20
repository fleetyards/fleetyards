import { describe, expect, it } from "vitest";
import type {
  PowerColumn,
  PowerColumnMember,
} from "@/frontend/composables/useLoadoutSim";
import {
  pipCells,
  pipClickTarget,
  setMemberTarget,
  toggleColumnOverrides,
} from "./allocation";

const member = (
  overrides: Partial<PowerColumnMember> = {},
): PowerColumnMember => ({
  portPath: "radar",
  allocated: 2,
  capacity: 5,
  fillable: 5,
  min: 2,
  ...overrides,
});

const column = (members: PowerColumnMember[]): PowerColumn =>
  ({
    ...members[0],
    family: "shield",
    members,
  }) as PowerColumn;

describe("setMemberTarget", () => {
  it("raises a part as far as the pool allows", () => {
    expect(setMemberTarget({}, member(), 5, 1)).toEqual({ radar: 3 });
  });

  it("switches a part off below its floor", () => {
    expect(setMemberTarget({}, member(), 1, 4)).toEqual({ radar: 0 });
  });

  it("cannot start a part the pool cannot afford", () => {
    expect(setMemberTarget({}, member({ allocated: 0 }), 3, 1)).toBeUndefined();
  });

  it("leaves an unchanged allocation alone", () => {
    expect(setMemberTarget({}, member(), 2, 4)).toBeUndefined();
  });
});

describe("pipClickTarget", () => {
  it("toggles a shared part between its floor and off", () => {
    const left = member({
      portPath: "left",
      allocated: 2,
      min: 2,
      capacity: 3,
    });
    const right = member({
      portPath: "right",
      allocated: 3,
      min: 2,
      capacity: 3,
    });
    const shields = column([left, right]);

    expect(pipClickTarget({}, shields, left, 2, 0)).toEqual({ left: 0 });
    expect(pipClickTarget({}, shields, right, 2, 0)).toEqual({ right: 2 });
  });

  it("ignores headroom that cannot be filled", () => {
    const part = member({ fillable: 3 });
    expect(pipClickTarget({}, column([part]), part, 4, 5)).toBeUndefined();
  });
});

describe("toggleColumnOverrides", () => {
  it("drains a column with power and fills one without", () => {
    const on = column([
      member({ portPath: "a" }),
      member({ portPath: "b", allocated: 0 }),
    ]);
    const off = column([member({ portPath: "a", allocated: 0, fillable: 4 })]);

    expect(toggleColumnOverrides({}, on)).toEqual({ a: 0, b: 0 });
    expect(toggleColumnOverrides({}, off)).toEqual({ a: 4 });
  });
});

describe("pipCells", () => {
  it("merges the floor into one block and adds a cell per optional segment", () => {
    expect(pipCells(member())).toEqual([
      { level: 2, span: 2 },
      { level: 3, span: 1 },
      { level: 4, span: 1 },
      { level: 5, span: 1 },
    ]);
  });
});
