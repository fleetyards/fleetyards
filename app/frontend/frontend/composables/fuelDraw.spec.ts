import { describe, expect, it } from "vitest";
import { type Hardpoint, HardpointCategoryEnum } from "@/services/fyApi";
import { fuelDraw, fuelEndurance } from "./fuelDraw";

const thruster = (
  category: HardpointCategoryEnum,
  thrustCapacity: number,
  fuelBurnScuPer10KNewton?: number,
) =>
  ({
    category,
    component: { typeData: { thrustCapacity, fuelBurnScuPer10KNewton } },
  }) as unknown as Hardpoint;

// The Scorpius as erkul reads it: four 3.8 MN mains, two 2 MN retros and
// eight 1.25 MN maneuvering thrusters, all at 1.274 µSCU/s per 10 kN.
const scorpius = [
  ...Array.from({ length: 4 }, () =>
    thruster(HardpointCategoryEnum.MAIN_THRUSTERS, 3_800_000, 1.274e-6),
  ),
  ...Array.from({ length: 2 }, () =>
    thruster(HardpointCategoryEnum.RETRO_THRUSTERS, 2_000_000, 1.274e-6),
  ),
  ...Array.from({ length: 8 }, () =>
    thruster(HardpointCategoryEnum.MANEUVERING_THRUSTERS, 1_250_000, 1.274e-6),
  ),
];

describe("fuelDraw", () => {
  it("sums every thruster's draw at full thrust, and the mains alone", () => {
    const draw = fuelDraw(scorpius);

    expect(draw.main).toBeCloseTo(1936.48);
    expect(draw.all).toBeCloseTo(3720.08);
  });

  it("reads thrusters nested under another hardpoint", () => {
    const nacelle = {
      category: HardpointCategoryEnum.UNKNOWN,
      hardpoints: [
        thruster(HardpointCategoryEnum.MAIN_THRUSTERS, 1_000_000, 1e-6),
      ],
    } as unknown as Hardpoint;

    expect(fuelDraw([nacelle]).main).toBeCloseTo(100);
  });

  it("leaves out a thruster without the network draw", () => {
    expect(
      fuelDraw([thruster(HardpointCategoryEnum.MAIN_THRUSTERS, 3_800_000)]),
    ).toEqual({ all: 0, main: 0 });
  });
});

describe("fuelEndurance", () => {
  it("is how long a tank lasts at a draw, in seconds", () => {
    // 8.6 SCU on the mains: about 74 minutes.
    expect(Math.round(fuelEndurance(8.6, 1936.48)! / 60)).toBe(74);
  });

  it("has no answer for a ship that draws nothing", () => {
    expect(fuelEndurance(8.6, 0)).toBeUndefined();
  });
});
