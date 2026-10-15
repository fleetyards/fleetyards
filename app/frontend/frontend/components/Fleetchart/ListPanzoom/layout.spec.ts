import { describe, expect, it } from "vitest";
import {
  autoScreenHeightFactor,
  chartSize,
  layoutColumns,
  type FleetchartItemSize,
} from "./layout";

const ships = (count: number, width = 300, height = 80) =>
  Array.from({ length: count }, (): FleetchartItemSize => ({ width, height }));

const screen = { width: 1600, height: 900 };

// The panzoom chart's own margins, as the component subtracts them.
const columnHeight = (factor: number) => screen.height * factor - 120;

describe("layoutColumns", () => {
  it("starts a new column once the next item overflows", () => {
    expect(layoutColumns(ships(5, 100, 100), 250)).toEqual([
      [0, 1],
      [2, 3],
      [4],
    ]);
  });

  it("keeps an item taller than the column in a column of its own", () => {
    expect(
      layoutColumns(
        [
          { width: 10, height: 10 },
          { width: 10, height: 500 },
          { width: 10, height: 10 },
        ],
        100,
      ),
    ).toEqual([[0], [1], [2]]);
  });
});

describe("chartSize", () => {
  it("adds the widest item per column and the gaps between columns", () => {
    const sizes = [
      { width: 100, height: 50 },
      { width: 200, height: 50 },
      { width: 50, height: 50 },
    ];

    expect(chartSize(sizes, [[0, 1], [2]])).toEqual({
      width: 200 + 50 + 30,
      height: 140,
    });
  });
});

describe("autoScreenHeightFactor", () => {
  it("stays at 1x for a fleet that fits the screen", () => {
    expect(autoScreenHeightFactor(ships(6), screen, columnHeight)).toBe(1);
  });

  it("stays at 1x without items or a screen size", () => {
    expect(autoScreenHeightFactor([], screen, columnHeight)).toBe(1);
    expect(
      autoScreenHeightFactor(ships(6), { width: 0, height: 0 }, columnHeight),
    ).toBe(1);
  });

  it("grows a large fleet towards the screen's proportions", () => {
    const sizes = ships(800);
    const factor = autoScreenHeightFactor(sizes, screen, columnHeight);

    const at = (value: number) => {
      const { width, height } = chartSize(
        sizes,
        layoutColumns(sizes, columnHeight(value)),
      );

      return Math.abs(Math.log(width / height / (16 / 9)));
    };

    expect(factor).toBeGreaterThan(1);
    expect(at(factor)).toBeLessThan(at(1));
    expect(at(factor)).toBeLessThan(0.3);
  });
});
